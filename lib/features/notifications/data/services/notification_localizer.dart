import 'package:flutter/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/notification_model.dart';

class NotificationLocalizer {
  /// Localizes the notification title dynamically.
  /// If the title matches "{sender} sent you a message", it translates it
  /// based on current locale using l10n.notificationMessageSent.
  static String getLocalizedTitle(BuildContext context, AppNotification notif) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return notif.title;

    final title = notif.title.trim();

    // Check if it's a message notification
    final regex = RegExp(r'^(.*?)\s+sent you a message$', caseSensitive: false);
    final match = regex.firstMatch(title);
    if (match != null) {
      String sender = match.group(1)?.trim() ?? '';
      if (sender.toLowerCase() == 'user') {
        sender = l10n.notificationUser;
      }
      return l10n.notificationMessageSent(sender);
    }

    // Check Arabic pattern if stored in Arabic
    final arRegex = RegExp(r'^(?:أرسل لك|ارسل لك)\s+(.*?)\s+رسالة$', caseSensitive: false);
    final arMatch = arRegex.firstMatch(title);
    if (arMatch != null) {
      final sender = arMatch.group(1)?.trim() ?? '';
      return l10n.notificationMessageSent(sender);
    }

    // Check subscription notification title
    if (title.toLowerCase() == 'subscription activated' ||
        title == 'تم تفعيل الاشتراك') {
      return l10n.subscriptionActivatedTitle;
    }

    // Check complaint notification title
    if (title.toLowerCase() == 'new complaint filed' ||
        title == 'تم تقديم شكوى جديدة') {
      return l10n.notificationNewComplaintTitle;
    }

    // Check booking notifications titles
    if (title.toLowerCase() == 'new booking request' || title == 'طلب حجز جديد') {
      return l10n.notificationNewBookingTitle;
    }
    if (title.toLowerCase() == 'booking accepted' || title == 'تم قبول الحجز') {
      return l10n.notificationBookingAcceptedTitle;
    }
    if (title.toLowerCase() == 'booking completed' || title == 'اكتمل الحجز') {
      return l10n.notificationBookingCompletedTitle;
    }
    if (title.toLowerCase() == 'booking cancelled' || title == 'تم إلغاء الحجز') {
      return l10n.notificationBookingCancelledTitle;
    }

    return notif.title;
  }

  /// Localizes snippet bodies like "Images 5 📸" or "Sent a media file" or Subscription bodies
  static String getLocalizedBody(BuildContext context, AppNotification notif) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return notif.body;

    final body = notif.body.trim();

    // Check Subscription Activated body pattern:
    // "Congratulations! Your subscription to the Bronze Plan plan has been successfully activated."
    // or "مبروك! تم تفعيل اشتراكك في خطة Bronze Plan بنجاح."
    final subRegexEn = RegExp(
      r'^Congratulations!\s*Your subscription to the\s+(.*?)\s*(?:plan)?\s*has been successfully activated\.?$',
      caseSensitive: false,
    );
    final subMatchEn = subRegexEn.firstMatch(body);
    if (subMatchEn != null) {
      final rawPlan = subMatchEn.group(1)?.trim() ?? '';
      // Clean up duplicate "plan" suffix if present
      final cleanPlan = rawPlan.replaceAll(RegExp(r'\s+plan$', caseSensitive: false), '');
      return l10n.subscriptionActivatedBody(cleanPlan);
    }

    final subRegexAr = RegExp(
      r'^(?:مبروك!|تهانينا!)\s*تم تفعيل اشتراكك في خطة\s+(.*?)\s*بنجاح\.?$',
      caseSensitive: false,
    );
    final subMatchAr = subRegexAr.firstMatch(body);
    if (subMatchAr != null) {
      final rawPlan = subMatchAr.group(1)?.trim() ?? '';
      return l10n.subscriptionActivatedBody(rawPlan);
    }

    // Complaint filed pattern
    final complaintRegex = RegExp(
      r'^(?:A complaint has been filed against you regarding booking #|تم تقديم شكوى ضدك بخصوص الحجز #)(.*?)$',
      caseSensitive: false,
    );
    final complaintMatch = complaintRegex.firstMatch(body);
    if (complaintMatch != null) {
      final bookingId = complaintMatch.group(1)?.trim() ?? '';
      return l10n.notificationNewComplaintBody(bookingId);
    }

    // New Booking Request pattern
    final newBookingRegex = RegExp(
      r'^(?:You have received a new booking request #|لقد تلقيت طلب حجز جديد #)(.*?)$',
      caseSensitive: false,
    );
    final newBookingMatch = newBookingRegex.firstMatch(body);
    if (newBookingMatch != null) {
      final bookingId = newBookingMatch.group(1)?.trim() ?? '';
      return l10n.notificationNewBookingBody(bookingId);
    }

    // Booking Accepted pattern
    final acceptedRegex = RegExp(
      r'^(?:Your booking #|تم قبول حجزك #)(.*?)(?:\s+has been accepted by the provider|\s+من قبل الفني)$',
      caseSensitive: false,
    );
    final acceptedMatch = acceptedRegex.firstMatch(body);
    if (acceptedMatch != null) {
      final bookingId = acceptedMatch.group(1)?.trim() ?? '';
      return l10n.notificationBookingAcceptedBody(bookingId);
    }

    // Booking Completed pattern
    final completedRegex = RegExp(
      r'^(?:Your booking #|تم تحديد حجزك #)(.*?)(?:\s+has been marked as completed|\s+كمكتمل)$',
      caseSensitive: false,
    );
    final completedMatch = completedRegex.firstMatch(body);
    if (completedMatch != null) {
      final bookingId = completedMatch.group(1)?.trim() ?? '';
      return l10n.notificationBookingCompletedBody(bookingId);
    }

    // Booking Cancelled pattern
    final cancelledRegex = RegExp(
      r'^(?:Booking #|تم إلغاء الحجز #)(.*?)(?:\s+has been cancelled|)$',
      caseSensitive: false,
    );
    final cancelledMatch = cancelledRegex.firstMatch(body);
    if (cancelledMatch != null) {
      final bookingId = cancelledMatch.group(1)?.trim() ?? '';
      return l10n.notificationBookingCancelledBody(bookingId);
    }

    // Media file pattern
    if (body.toLowerCase() == 'sent a media file' || body == 'أرسل ملف وسائط') {
      return l10n.notificationSentMediaFile;
    }

    // Pattern like "Images 5 📸" or "5 Images 📸"
    final imgRegex = RegExp(r'(?:Images?\s*(\d+)|\b(\d+)\s*Images?)\s*📸?', caseSensitive: false);
    final imgMatch = imgRegex.firstMatch(body);
    if (imgMatch != null) {
      final countStr = imgMatch.group(1) ?? imgMatch.group(2) ?? '1';
      final count = int.tryParse(countStr) ?? 1;
      return l10n.notificationImages(count);
    }

    return notif.body;
  }

  /// Localizes relative time ago (e.g. 15d -> 15 يوم / 15d)
  static String formatTimeAgo(BuildContext context, DateTime d) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(d);

    if (diff.inDays > 365) {
      final count = (diff.inDays / 365).floor();
      return l10n != null ? l10n.timeAgoYear(count) : '${count}y';
    }
    if (diff.inDays > 30) {
      final count = (diff.inDays / 30).floor();
      return l10n != null ? l10n.timeAgoMonth(count) : '${count}m';
    }
    if (diff.inDays > 0) {
      return l10n != null ? l10n.timeAgoDay(diff.inDays) : '${diff.inDays}d';
    }
    if (diff.inHours > 0) {
      return l10n != null ? l10n.timeAgoHour(diff.inHours) : '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return l10n != null ? l10n.timeAgoMinute(diff.inMinutes) : '${diff.inMinutes}m';
    }
    return l10n != null ? l10n.timeAgoNow : 'now';
  }
}
