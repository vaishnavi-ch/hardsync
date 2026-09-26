const notes = {
  welcome: { title: 'A calmer way to get ready.', copy: 'Build confidence one conversation at a time.' },
  plans: { title: 'Pick the pace that works for you.', copy: 'Start free, or practise as often as you like with Pro.' },
  discover: {
    title: 'A little practice goes a long way.',
    copy: 'Pick a moment on your mind. We can help you find the words.'
  },
  practice: {
    title: 'A safe place to try.',
    copy: 'Take your time. Try a different approach whenever you need.'
  },
  grow: {
    title: 'Keep what worked.',
    copy: 'Notice what felt right, then take it into the real conversation.'
  }
};

function showScreen(name) {
  document.querySelectorAll('[data-panel]').forEach(panel => panel.classList.toggle('active', panel.dataset.panel === name));
  document.querySelectorAll('[data-screen]').forEach(button => button.classList.toggle('active', button.dataset.screen === name));
  document.querySelector('.mockup-stage').classList.toggle('pair-view', name === 'welcome' || name === 'plans');
  document.querySelector('#note-title').textContent = notes[name].title;
  document.querySelector('#note-copy').textContent = notes[name].copy;
}

document.querySelectorAll('[data-screen]').forEach(button => button.addEventListener('click', () => showScreen(button.dataset.screen)));
document.querySelectorAll('[data-go]').forEach(button => button.addEventListener('click', () => showScreen(button.dataset.go)));

document.querySelectorAll('[data-review]').forEach(button => {
  button.addEventListener('click', () => {
    const review = button.dataset.review;
    document.querySelectorAll('[data-review]').forEach(item => item.classList.toggle('active', item === button));
    document.querySelectorAll('[data-review-panel]').forEach(panel => panel.classList.toggle('active', panel.dataset.reviewPanel === review));
  });
});


document.querySelectorAll('[data-tier]').forEach(button => {
  button.addEventListener('click', () => {
    document.querySelectorAll('[data-tier]').forEach(item => item.classList.toggle('active', item === button));
    const yearly = button.dataset.tier === 'yearly';
    document.querySelectorAll('[data-price]').forEach(price => { price.textContent = yearly ? '$12' : '$20'; });
    document.querySelectorAll('.plan-price small').forEach(label => { label.textContent = yearly ? '/ month, billed yearly' : '/ month'; });
  });
});

document.querySelectorAll('[data-plan]').forEach(button => {
  button.addEventListener('click', () => {
    document.querySelectorAll('[data-plan]').forEach(item => item.classList.toggle('selected', item === button));
  });
});
