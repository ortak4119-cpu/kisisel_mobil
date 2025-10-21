import 'package:intl/intl.dart';

String timerFormatter(int seconds) {
  int minutes = (seconds ~/ 60);
  int remainingSeconds = seconds % 60;
  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');
  return "$formattedMinutes:$formattedSeconds";
}

String dateFormatterYearMonthDay(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatPhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
}

String daysUntil(String dateString) {
  if (dateString.isEmpty) return "0";
  DateTime givenDate = DateFormat("yyyy-MM-dd").parse(dateString);
  DateTime now = DateTime.now();

  return givenDate.difference(now).inDays.toString();
}

String daysUntilWithDateTime(DateTime givenDate) {
  DateTime now = DateTime.now();
  return givenDate.difference(now).inDays.toString();
}

String daysUntilProjectDetail(DateTime givenDate) {
  DateTime now = DateTime.now();
  int daysDifference = givenDate.difference(now).inDays;

  String formattedDate =
      DateFormat('dd/MM/yyyy - EEEE', 'tr_TR').format(givenDate);
  return '⏱️ Son tarih: $formattedDate';
}

String formatDateProjectDetail(DateTime dateTime) {
  // Gün ve ayın iki haneli olması için padLeft kullanılıyor
  String day = dateTime.day.toString().padLeft(2, '0');
  String month = dateTime.month.toString().padLeft(2, '0');
  String year = dateTime.year.toString();

  // İstediğiniz formata dönüştürün
  return '$day/$month/$year';
}

String formatTimeAgo(DateTime dateTime) {
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return " • az önce";
  } else if (difference.inMinutes == 1) {
    return " • 1dk önce";
  } else if (difference.inMinutes < 60) {
    return " • ${difference.inMinutes}dk önce";
  } else if (difference.inHours == 1) {
    return " • 1s önce";
  } else if (difference.inHours < 24) {
    return " • ${difference.inHours}s önce";
  } else if (difference.inDays == 1) {
    return " • 1g önce";
  } else if (difference.inDays < 365) {
    return " • ${difference.inDays}g önce";
  } else if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    if (years == 1) {
      return " • 1y önce";
    } else {
      return " • ${years}y önce";
    }
  } else {
    return " • bir süre önce";
  }
}



