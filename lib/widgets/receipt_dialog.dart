import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'error_snackbar.dart';

/// The receipt/title-register PDF dialog, shared by the two flows that receive
/// `Documents[]` (each `{ParcelNumber, UnitNumber, BlockNumber, FileName,
/// FileBase64, ...}`) from the backend:
///   - personal_information -> POST /api/payment-completion/complete
///   - pending_payment_screen -> GET /api/PendingPayment (result 3)
/// Both show the same dialog with a "View"/"عرض" button per document that opens
/// the base64 PDF in the device viewer via the native `openPdf` channel.

const MethodChannel _downloadChannel = MethodChannel('lrc/downloads');

/// Button label for one document. With several documents the label has to
/// identify WHICH property it is, so it includes the unit and block when the
/// backend supplied them (they are frequently absent — unit comes back as 0 and
/// block as null for a plain parcel, and neither is shown then).
String receiptDocumentLabel(Map<String, dynamic> doc, bool isEnglish) {
  final parts = <String>[];

  final parcel = (doc['ParcelNumber'] ?? '').toString().trim();
  if (parcel.isNotEmpty) {
    parts.add(isEnglish ? 'Parcel $parcel' : 'العقار $parcel');
  }

  final unit = (doc['UnitNumber'] ?? '').toString().trim();
  if (unit.isNotEmpty && unit != '0') {
    parts.add(isEnglish ? 'Unit $unit' : 'القسم $unit');
  }

  final block = (doc['BlockNumber'] ?? '').toString().trim();
  if (block.isNotEmpty && block != '0' && block.toLowerCase() != 'null') {
    parts.add(isEnglish ? 'Block $block' : 'البلوك $block');
  }

  final view = isEnglish ? 'View' : 'عرض';
  if (parts.isEmpty) return view;
  return '$view — ${parts.join(isEnglish ? ', ' : ' - ')}';
}

/// Decodes a base64 PDF and hands it to the native side to open in the device's
/// PDF viewer.
Future<void> openReceiptDocument(
  BuildContext context,
  String base64Data,
  String fileName,
) async {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  try {
    final bytes = base64Decode(base64Data.replaceAll(RegExp(r'\s'), ''));
    await _downloadChannel.invokeMethod('openPdf', {
      'bytes': bytes,
      'fileName': fileName,
    });
  } catch (e) {
    if (kDebugMode) debugPrint('[openPdf] ERROR $e');
    if (context.mounted) {
      ErrorSnackbar.show(
        context: context,
        message: isEnglish
            ? 'Could not open the document.'
            : 'تعذّر فتح المستند.',
      );
    }
  }
}

/// Shows the success dialog listing every returned document behind a View
/// button. [title] and [body] let the caller word it for its own flow.
Future<void> showReceiptDialog(
  BuildContext context,
  List<Map<String, dynamic>> documents, {
  String? title,
  String? body,
}) async {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title ?? (isEnglish ? 'Payment completed' : 'تم إتمام الدفع'),
              style: AppType.h2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body ??
                (isEnglish
                    ? 'Your document is ready. Tap View to open it.'
                    : 'المستند جاهز. اضغط عرض لفتحه.'),
            style: AppType.body,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < documents.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: AppButtons.primary(),
                  onPressed: () {
                    final doc = documents[i];
                    final base64Data = (doc['FileBase64'] ?? '').toString();
                    final fileName =
                        (doc['FileName'] ?? 'document_${i + 1}.pdf').toString();
                    if (base64Data.isEmpty) return;
                    openReceiptDocument(ctx, base64Data, fileName);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    documents.length == 1
                        ? (isEnglish ? 'View' : 'عرض')
                        : receiptDocumentLabel(documents[i], isEnglish),
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(isEnglish ? 'Done' : 'تم'),
        ),
      ],
    ),
  );
}

/// Pulls the documents list out of a payment/completion response body,
/// tolerating the shapes the backend uses (`payment.Documents`,
/// `Payment.Documents`, or a flat top-level `Documents`).
List<Map<String, dynamic>> extractDocuments(Map<String, dynamic> decoded) {
  dynamic docs;
  final payment = decoded['payment'] ?? decoded['Payment'];
  if (payment is Map) {
    docs = payment['Documents'] ?? payment['documents'];
  }
  docs ??= decoded['Documents'] ?? decoded['documents'];

  if (docs is List) {
    return docs.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const [];
}
