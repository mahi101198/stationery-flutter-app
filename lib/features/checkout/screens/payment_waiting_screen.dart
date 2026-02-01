import 'package:flutter/material.dart';

class PaymentWaitingScreen extends StatelessWidget {
  final String message;
  final String? subMessage;
  
  const PaymentWaitingScreen({
    super.key,
    this.message = 'Processing Payment',
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading animation
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5A7C8A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Main message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16161E),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Sub message
                if (subMessage != null)
                  Text(
                    subMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF737378),
                    ),
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Please do not close this screen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF737378),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

