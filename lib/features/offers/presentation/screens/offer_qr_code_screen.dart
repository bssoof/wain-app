import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';

class OfferQRCodeScreen extends StatefulWidget {
  final ClaimResult claimResult;
  final Offer offer;
  final String venueName;

  const OfferQRCodeScreen({
    super.key,
    required this.claimResult,
    required this.offer,
    required this.venueName,
  });

  @override
  State<OfferQRCodeScreen> createState() => _OfferQRCodeScreenState();
}

class _OfferQRCodeScreenState extends State<OfferQRCodeScreen> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final remaining = widget.claimResult.expiresAt.difference(now);
    
    if (remaining.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer.cancel();
    } else {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerText {
    final minutes = _remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingTime == Duration.zero;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'رمز الخصم',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.venueName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.offer.discountText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // QR Code
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: isExpired
                          ? Icon(
                              Icons.error_outline,
                              size: 150,
                              color: Colors.grey.shade300,
                            )
                          : QrImageView(
                              data: widget.claimResult.token,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                            ),
                    ),

                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                      child: Column(
                        children: [
                          Text(
                            isExpired ? 'انتهت صلاحية الرمز' : 'صالح لمدة',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.green.shade800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timerText,
                             style: TextStyle(
                              color: isExpired ? Colors.red : Colors.green.shade800,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier', 
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (isExpired)
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           children: [
                             Text(
                               'تمت الاستفادة من العرض',
                               style: TextStyle(
                                 color: Colors.red.shade700,
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 4),
                              const Text(
                               'انتهت فترة الصلاحية',
                               style: TextStyle(color: Colors.grey),
                             ),
                           ],
                         ),
                       )
                    else 
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'أظهر هذا الرمز للكاشير',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
