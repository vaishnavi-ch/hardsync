class ReplayController {
  double? pendingSeek;
  void Function(double seconds)? seek;
  void Function()? download;
}
