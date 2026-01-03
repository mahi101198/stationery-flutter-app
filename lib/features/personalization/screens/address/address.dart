import 'package:flutter/material.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              centerTitle: true,
              title: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text("Addresses"),
              ),
            ),

            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 1),
                  Image.asset(
                    Theme.of(context).brightness == Brightness.light
                        ? "assets/illustration/no_result_light.png"
                        : "assets/illustration/no_result_dark.png",
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  const SizedBox(height: 16),
                  const Text('No saved addresses!'),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
