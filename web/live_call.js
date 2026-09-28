/* Browser side of the authenticated Gemini Live audio bridge. */
let config;
let socket;
let stream;
let context;
let processor;
let videoTimer;
let finishing;
let started = false;
let assistantSpeaking = false;
let assistantTurnComplete = false;
let muted = false;
let nextAudioTime = 0;
const activeAudio = new Set();
let avatarMediaSource;
let avatarSourceBuffer;
const avatarQueue = [];
let dailyCall;

function getAudioContext() {
  if (!context || context.state === 'closed') {
    context = new (window.AudioContext || window.webkitAudioContext)();
  }
  return context;
}

const $ = (id) => document.getElementById(id);
const send = (type, data = {}) => {
  const message = JSON.stringify({ type, ...data });
  if (window.HardSync) HardSync.postMessage(message);
  else parent.postMessage(message, location.origin);
};

function bytesToBase64(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function pcm16(samples, inputRate) {
  const ratio = inputRate / 16000;
  const length = Math.floor(samples.length / ratio);
  const output = new Int16Array(length);
  for (let index = 0; index < length; index++) {
    const sample = Math.max(-1, Math.min(1, samples[Math.floor(index * ratio)]));
    output[index] = sample < 0 ? sample * 32768 : sample * 32767;
  }
  return bytesToBase64(new Uint8Array(output.buffer));
}

function sendSocket(type, data) {
  if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type, data }));
}

function stopPlayback() {
  for (const source of activeAudio) {
    try { source.stop(); } catch (_) {}
  }
  activeAudio.clear();
  nextAudioTime = context?.currentTime ?? 0;
  assistantSpeaking = false;
  assistantTurnComplete = false;
  document.body.classList.remove('assistant-speaking');
  avatarQueue.length = 0;
  if (avatarSourceBuffer && !avatarSourceBuffer.updating) {
    try { avatarSourceBuffer.abort(); } catch (_) {}
  }
}

// Live Avatar sends the AI's reply as a continuous fragmented-MP4 stream
// (video with the speech audio already baked into its audio track), delivered
// as ~16KB chunks over the same WebSocket. A single chunk is never a
// standalone playable file — only the very first one carries the ftyp/moov
// header — so chunks must be fed into one ongoing MediaSource SourceBuffer in
// order, not treated as separate blobs.
function pumpAvatarQueue() {
  if (!avatarSourceBuffer || avatarSourceBuffer.updating || avatarQueue.length === 0) return;
  const chunk = avatarQueue.shift();
  try {
    avatarSourceBuffer.appendBuffer(chunk);
  } catch (error) {
    console.error('[avatar] appendBuffer threw', error.name, error.message, 'chunkBytes=', chunk.length, 'queueLeft=', avatarQueue.length);
    send('error', { message: `Avatar video appendBuffer failed: ${error.name}: ${error.message}` });
  }
}

function initAvatarStream(mime) {
  const video = $('avatar');
  avatarMediaSource = new MediaSource();
  video.src = URL.createObjectURL(avatarMediaSource);
  // Only swap away from the static illustration once a frame is genuinely
  // decoding - never reveal the bare <video> element while it has nothing to
  // show, which is what renders as a giant broken play icon on some devices.
  video.addEventListener('playing', () => {
    video.style.display = 'block';
    $('avatarIllustration').hidden = true;
    // Starting muted guarantees autoplay is never blocked; unmuting an
    // already-playing element (rather than starting unmuted) isn't subject
    // to that same restriction.
    video.muted = false;
  }, { once: true });
  avatarMediaSource.addEventListener('sourceopen', () => {
    console.log('[avatar] sourceopen fired, mime=', mime);
    const candidates = [
      `${mime}; codecs="avc1.42c020,mp4a.40.2"`,
      `${mime}; codecs="avc1.4d0020,mp4a.40.2"`,
      `${mime}; codecs="avc1.42c020"`,
      mime,
    ];
    let lastError;
    for (const candidate of candidates) {
      const supported = MediaSource.isTypeSupported(candidate);
      console.log('[avatar] candidate', candidate, 'isTypeSupported=', supported);
      if (!supported) continue;
      try {
        avatarSourceBuffer = avatarMediaSource.addSourceBuffer(candidate);
        console.log('[avatar] addSourceBuffer succeeded with', candidate);
        break;
      } catch (error) {
        lastError = error;
        console.error('[avatar] addSourceBuffer threw for', candidate, error.name, error.message);
      }
    }
    if (!avatarSourceBuffer) {
      send('error', { message: `Avatar video codec unsupported on this device: ${lastError?.message || 'no candidate mime type worked'}` });
      return;
    }
    avatarSourceBuffer.mode = 'sequence';
    avatarSourceBuffer.addEventListener('updateend', pumpAvatarQueue);
    avatarSourceBuffer.addEventListener('error', () => {
      console.error('[avatar] sourceBuffer error event fired');
      send('error', { message: 'Avatar video stream error (SourceBuffer).' });
    });
    pumpAvatarQueue();
  }, { once: true });
  avatarMediaSource.addEventListener('sourceended', () => console.log('[avatar] mediaSource sourceended'));
  avatarMediaSource.addEventListener('sourceclose', () => console.log('[avatar] mediaSource sourceclose'));
  video.addEventListener('error', () => console.error('[avatar] video element error', video.error?.code, video.error?.message));
}

function feedAvatarVideo(mime, base64) {
  const bytes = Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
  if (!avatarMediaSource) initAvatarStream(mime);
  avatarQueue.push(bytes);
  pumpAvatarQueue();
  $('avatar').play().catch((error) => {
    send('error', { message: `Avatar video play() blocked: ${error.message}` });
  });
}

function play(data) {
  if (!context || context.state !== 'running') return;
  const raw = Uint8Array.from(atob(data), (char) => char.charCodeAt(0));
  const pcm = new Int16Array(raw.buffer);
  const buffer = context.createBuffer(1, pcm.length, 24000);
  const channel = buffer.getChannelData(0);
  for (let index = 0; index < pcm.length; index++) channel[index] = pcm[index] / 32768;

  const source = context.createBufferSource();
  source.buffer = buffer;
  source.connect(context.destination);
  if (recordDest) {
    try { source.connect(recordDest); } catch (_) {}
  }
  assistantSpeaking = true;
  document.body.classList.add('assistant-speaking');
  assistantTurnComplete = false;
  activeAudio.add(source);
  source.onended = () => {
    activeAudio.delete(source);
    if (activeAudio.size === 0 && assistantTurnComplete) {
      assistantSpeaking = false;
      document.body.classList.remove('assistant-speaking');
    }
  };
  nextAudioTime = Math.max(nextAudioTime, context.currentTime + 0.03);
  source.start(nextAudioTime);
  nextAudioTime += buffer.duration;
}

// Lets the user drag their own camera preview anywhere on screen and
// pinch it bigger/smaller, since it's the one thing they most want control
// over during a call. Double-tap resets it to the default corner spot.
function setupDraggableLocalVideo() {
  const el = $('local');
  const pointers = new Map();
  let converted = false;
  let dragOffsetX = 0;
  let dragOffsetY = 0;
  let pinching = false;
  let startDist = 1;
  let startWidth = 0;
  let lastTapTime = 0;

  function convertToAbsolute() {
    if (converted) return;
    const rect = el.getBoundingClientRect();
    el.style.left = `${rect.left}px`;
    el.style.top = `${rect.top}px`;
    el.style.right = 'auto';
    el.style.bottom = 'auto';
    converted = true;
  }

  // Reserve space at top (header/HUD) and bottom (native call control dock)
  // so the thumbnail can never be dragged under native buttons, which sit
  // above the WebView in touch hit-test order and would swallow drags.
  const TOP_SAFE = 190;
  const BOTTOM_SAFE = 150;

  function clampPosition() {
    const rect = el.getBoundingClientRect();
    const left = Math.max(4, Math.min(window.innerWidth - rect.width - 4, rect.left));
    const top = Math.max(TOP_SAFE, Math.min(window.innerHeight - rect.height - BOTTOM_SAFE, rect.top));
    el.style.left = `${left}px`;
    el.style.top = `${top}px`;
  }

  el.addEventListener('pointerdown', (event) => {
    try { el.setPointerCapture(event.pointerId); } catch (_) {}
    convertToAbsolute();
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    const rect = el.getBoundingClientRect();
    if (pointers.size === 1) {
      dragOffsetX = event.clientX - rect.left;
      dragOffsetY = event.clientY - rect.top;
    } else if (pointers.size === 2) {
      pinching = true;
      const pts = [...pointers.values()];
      startDist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y) || 1;
      startWidth = rect.width;
    }
  });

  el.addEventListener('pointermove', (event) => {
    if (!pointers.has(event.pointerId)) return;
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    if (pinching && pointers.size === 2) {
      const pts = [...pointers.values()];
      const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y) || 1;
      const width = Math.max(90, Math.min(window.innerWidth * 0.75, startWidth * (dist / startDist)));
      el.style.width = `${width}px`;
      el.style.maxWidth = 'none';
    } else if (pointers.size === 1 && !pinching) {
      el.style.left = `${event.clientX - dragOffsetX}px`;
      el.style.top = `${event.clientY - dragOffsetY}px`;
    }
  });

  const endPointer = (event) => {
    try { el.releasePointerCapture(event.pointerId); } catch (_) {}
    pointers.delete(event.pointerId);
    if (pointers.size < 2) pinching = false;
    if (pointers.size === 0) {
      clampPosition();
      const now = Date.now();
      if (now - lastTapTime < 300) {
        el.style.width = '';
        el.style.maxWidth = '';
        el.style.left = 'auto';
        el.style.right = '16px';
        el.style.top = '200px';
        el.style.bottom = 'auto';
        converted = false;
      }
      lastTapTime = now;
    }
  };
  el.addEventListener('pointerup', endPointer);
  el.addEventListener('pointercancel', endPointer);
}

function captureVideoFrame() {
  if (!config?.video || !stream) return;
  const video = $('local');
  if (!video.videoWidth) return;
  const canvas = document.createElement('canvas');
  canvas.width = 320;
  canvas.height = Math.max(1, Math.round(video.videoHeight * 320 / video.videoWidth));
  canvas.getContext('2d').drawImage(video, 0, 0, canvas.width, canvas.height);
  canvas.toBlob(async (blob) => {
    if (socket?.readyState === WebSocket.OPEN && blob) {
      sendSocket('video', bytesToBase64(new Uint8Array(await blob.arrayBuffer())));
    }
  }, 'image/jpeg', 0.7);
}

// Tavus's photoreal replica is delivered over a Daily.co WebRTC room (the
// `config.url` Tavus handed back), not our own raw WebSocket protocol. Daily
// hands us real MediaStreamTracks directly, so both the replica's video/audio
// and our own local camera/mic are attached straight to the existing <video>
// elements instead of going through the MediaSource/AudioContext pipeline
// used for the plain Gemini Live bridge.
function attachDailyTrack(el, track, kind) {
  const current = el.srcObject instanceof MediaStream ? el.srcObject : new MediaStream();
  const existing = kind === 'video' ? current.getVideoTracks() : current.getAudioTracks();
  if (existing[0] === track) return;
  existing.forEach((t) => current.removeTrack(t));
  if (track) current.addTrack(track);
  if (el.srcObject !== current) el.srcObject = current;
}

function updateDailyParticipant(participant) {
  if (!participant) return;
  const videoTrack = participant.tracks?.video?.persistentTrack;
  const audioTrack = participant.tracks?.audio?.persistentTrack;
  if (participant.local) {
    if (videoTrack) attachDailyTrack($('local'), videoTrack, 'video');
    return;
  }
  const video = $('avatar');
  if (videoTrack) attachDailyTrack(video, videoTrack, 'video');
  if (audioTrack) attachDailyTrack(video, audioTrack, 'audio');
  if (videoTrack || audioTrack) {
    video.muted = false;
    video.style.display = 'block';
    $('avatarIllustration').hidden = true;
    video.play().catch((error) => send('error', { message: `Avatar video play() blocked: ${error.message}` }));
  }
}

async function joinTavus() {
  try {
    const call = window.DailyIframe.createCallObject({ subscribeToTracksAutomatically: true });
    dailyCall = call;
    call.on('joined-meeting', () => {
      $('status').textContent = 'Listening…';
      send('connected');
    });
    call.on('participant-joined', (event) => updateDailyParticipant(event.participant));
    call.on('participant-updated', (event) => updateDailyParticipant(event.participant));
    call.on('left-meeting', () => { if (started) send('left'); });
    call.on('error', (event) => send('error', { message: event?.errorMsg || 'Tavus call error.' }));
    await call.join({
      url: config.url,
      userName: 'You',
      startVideoOff: config.video === false,
      startAudioOff: config.mic === false,
    });
    if (config.mode === 'video') setupDraggableLocalVideo();
  } catch (error) {
    started = false;
    $('status').textContent = 'Allow microphone/camera access, then tap to start.';
    $('status').style.display = 'block';
    $('join').textContent = 'Start call';
    $('join').hidden = false;
    send('user-action-required', { message: error.message });
  }
}

function waitingLabel() {
  const name = (config?.personaName || '').trim();
  return name ? `Waiting for ${name} to join…` : 'Connecting…';
}

async function join() {
  if (started || !config) return;
  started = true;
  $('join').hidden = true;
  $('status').textContent = waitingLabel();
  if (config.realtimeProvider === 'tavus') return joinTavus();
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      audio: config.mic === false ? false : {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      },
      video: config.video !== false && config.mode === 'video',
    });
    $('local').srcObject = stream;
    if (config.mode === 'video') setupDraggableLocalVideo();
    context = getAudioContext();
    await context.resume();

    const input = context.createMediaStreamSource(stream);
    const silentOutput = context.createGain();
    silentOutput.gain.value = 0;
    processor = context.createScriptProcessor(4096, 1, 1);
    processor.onaudioprocess = (event) => {
      // Don't feed speaker echo back to Gemini while it is talking. This avoids
      // false interruptions and the counterpart claiming the user cut it off.
      if (socket?.readyState === WebSocket.OPEN && !assistantSpeaking && !muted) {
        sendSocket('audio', pcm16(event.inputBuffer.getChannelData(0), context.sampleRate));
      }
    };
    input.connect(processor);
    processor.connect(silentOutput);
    silentOutput.connect(context.destination);

    socket = new WebSocket(config.url);
    socket.onopen = () => {
      $('status').textContent = 'Authenticating with Gemini…';
      sendSocket('auth', { accessToken: config.auth });
      videoTimer = setInterval(captureVideoFrame, 1000);
    };
    socket.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.type === 'connected') {
        $('status').textContent = 'Listening…';
        send('connected');
      } else if (message.type === 'audio') {
        play(message.data);
      } else if (message.type === 'avatar_video') {
        feedAvatarVideo(message.mime, message.data);
      } else if (message.type === 'utterance') {
        if (message.role === 'replica') assistantSpeaking = true;
        send('utterance', message);
      } else if (message.type === 'turn_complete') {
        assistantTurnComplete = true;
        if (activeAudio.size === 0) {
          assistantSpeaking = false;
          document.body.classList.remove('assistant-speaking');
        }
        send('turn_complete');
      } else if (message.type === 'interrupted') {
        stopPlayback();
        send('interrupted');
      } else if (message.type === 'error') {
        $('status').textContent = message.message;
        send('error', { message: message.message });
      } else if (message.type === 'analysis') {
        send('analysis', message);
      }
    };
    socket.onerror = () => send('error', { message: 'Could not connect to the audio service.' });
    socket.onclose = () => {
      if (started) send('left');
    };
  } catch (error) {
    started = false;
    $('status').textContent = 'Allow microphone access, then tap to start.';
    $('status').style.display = 'block';
    $('join').textContent = config?.mode === 'video' ? 'Start call' : 'Start audio call';
    $('join').hidden = false;
    send('user-action-required', { message: error.message });
    stream?.getTracks().forEach((track) => track.stop());
    stream = null;
    context?.close();
    context = null;
  }
}

function finish() {
  if (finishing) return finishing;
  finishing = (async () => {
    clearInterval(videoTimer);
    started = false;
    if (dailyCall) {
      try { await dailyCall.leave(); } catch (_) {}
      try { await dailyCall.destroy(); } catch (_) {}
      dailyCall = null;
      send('finished');
      return;
    }
    stopPlayback();
    if (avatarMediaSource?.readyState === 'open') {
      try { avatarMediaSource.endOfStream(); } catch (_) {}
    }
    try { sendSocket('end'); } catch (_) {}
    try { socket?.close(); } catch (_) {}
    stream?.getTracks().forEach((track) => track.stop());
    await context?.close();
    send('finished');
  })();
  return finishing;
}

window.addEventListener('message', (event) => {
  // Accept messages only from the direct parent frame.
  // We intentionally skip the origin check because location.origin can be
  // 'null' (as a string) on some localhost setups, causing valid messages
  // to be silently dropped.
  if (event.source !== parent || typeof event.data !== 'string') return;
  let message;
  try { message = JSON.parse(event.data); } catch (_) { return; }
  if (message.type === 'init' && !config) {
    config = message;
    if (config.avatarUrl) $('avatarIllustration').src = config.avatarUrl;
    if (config.mode !== 'video') $('avatarIllustration').hidden = true;
    $('join').disabled = false;
    // The host app already collected a real user gesture ("Begin Call") before
    // ever loading this page, so auto-join for every mode by default. Only
    // fall back to a manual tap if the host explicitly asks for one, or if
    // join() itself fails (e.g. permission denied) and re-shows this button.
    $('join').textContent = config.mode === 'video' ? 'Start call' : 'Start audio call';
    if (config.autoJoin !== false) join();
    else $('join').hidden = false;
  } else if (message.type === 'finish' || message.type === 'leave') {
    finish();
  } else if (message.type === 'toggle_mic') {
    muted = !muted;
    if (dailyCall) dailyCall.setLocalAudio(!muted);
    else stream?.getAudioTracks().forEach((track) => { track.enabled = !muted; });
  } else if (message.type === 'toggle_camera') {
    if (dailyCall) {
      const enabled = dailyCall.localVideo();
      dailyCall.setLocalVideo(!enabled);
    } else {
      stream?.getVideoTracks().forEach((track) => { track.enabled = !track.enabled; });
    }
  } else if (message.type === 'join') {
    join();
  }
});

$('join').onclick = join;
send('ready');
