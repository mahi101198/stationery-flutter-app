import 'package:flutter/material.dart';
import 'package:rps_stationery/constants.dart';

class NoNotification extends StatelessWidget {
  const NoNotification({super.key});

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
                child: Text("Notifications"),
              ),
            ),

            SliverFillRemaining(
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
                      'No new notifications!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
