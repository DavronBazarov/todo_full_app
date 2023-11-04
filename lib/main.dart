import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:todo_full_app/providers/auth.dart';
import 'package:todo_full_app/providers/task_provider.dart';
import 'package:todo_full_app/screens/auth_screen.dart';
import 'package:todo_full_app/screens/completed_task_screen.dart';
import 'package:todo_full_app/screens/home_screen.dart';
import 'package:todo_full_app/screens/splash_screen.dart';
import 'package:connection_notifier/connection_notifier.dart';

import 'models/task.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final Directory dir = await getApplicationDocumentsDirectory();
  final String path = dir.path;
  await Hive.initFlutter(path);
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await Hive.initFlutter();

  Hive.registerAdapter<Task>(TaskAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Auth()),
        ChangeNotifierProxyProvider<Auth, TaskProvider>(
          create: (context) => TaskProvider(),
          update: (context, auth, previousProducts) =>
              TaskProvider()..setParams(auth.token, auth.userId),
        ),
      ],
      child: Consumer<Auth>(builder: (context, authData, child) {
        print("auth ==== ${authData.isAuth}");
        return ConnectionNotifier(
          disconnectedDuration: const Duration(seconds: 3),
          disconnectedContent: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.signal_wifi_connected_no_internet_4),
                  SizedBox(width: 10),
                  Text("Internet",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              )),
          connectedContent: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.check_mark_circled_solid),
                  SizedBox(width: 10),
                  Text("Internet",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              )),
          child: MaterialApp(
            builder: (context, widget) {
              return ResponsiveWrapper.builder(
                BouncingScrollWrapper.builder(context, widget!),
                defaultScale: true,
                breakpoints: [
                  const ResponsiveBreakpoint.resize(600, name: MOBILE),
                  const ResponsiveBreakpoint.autoScale(700, name: TABLET),
                  const ResponsiveBreakpoint.resize(800, name: DESKTOP),
                  const ResponsiveBreakpoint.autoScale(1700, name: "4K"),
                ],
              );
            },
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              primaryColor: const Color(0xff916BFE),
              useMaterial3: true,
              canvasColor: const Color(0xffd1faff),
              // primaryColor: const Color(0xff0c89dd),
            ),
            home: authData.isAuth
                ? const HomeScreen()
                : FutureBuilder(
              future: authData.autoLogIn(),
              builder: (ctx, autoLoginData) {
                if (autoLoginData.connectionState ==
                    ConnectionState.waiting) {
                  return const SplashScreen();
                } else {
                  return const AuthScreen();
                }
              },
            ),
            routes: {
              AuthScreen.routeName: (context) => const AuthScreen(),
              HomeScreen.routeName: (context) => const HomeScreen(),
              CompletedTasksScreen.routeName: (context) =>
                  CompletedTasksScreen(),
            },
          ),
        );
      }));
  }
}
