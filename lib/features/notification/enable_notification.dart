import 'package:flutter/material.dart';
import 'package:rps_stationery/constants.dart';

class EnableNotification extends StatelessWidget {
  const EnableNotification({super.key, required this.onEnableClick});

  final VoidCallback onEnableClick;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          defaultPadding * 2,
          0,
          defaultPadding * 2,
          defaultPadding * 3,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onEnableClick,
            child: const Text("Enable Notifications"),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              centerTitle: true,
              title: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text("Notifications"),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: defaultPadding * 2),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Theme.of(context).brightness == Brightness.light
                            ? "assets/illustration/enable_notification_light.png"
                            : "assets/illustration/enable_notification_dark.png",
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      Text(
                        'Push Notifications are currently turned off',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: defaultPadding / 1.5),
                      Text(
                        'Enabling push notifications allows us to send you info about our new products, sales, events and more.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
