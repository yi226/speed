extension StringExtension on String {
  double toDouble() {
    if (isEmpty || this == '-') {
      return 0;
    }
    return double.parse(this);
  }

  int toInt() {
    if (isEmpty || this == '-') {
      return 0;
    }
    return int.parse(this);
  }
}
