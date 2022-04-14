import 'dart:convert' as convert;

import 'package:fitbitter/fitbitter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  } //build
}

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);
  String fitbitClientID = '238DFB';
  String fitbitClientSecret = 'd7793a7cbec8474d9c079cad75dda3da';
  String fitbitRedirectUri = "x://callbackscreen";
  String fitbitCallbackScheme = 'x';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static const route = '/';
  static const routename = 'HomePage';
  String? userId;
  @override
  Widget build(BuildContext context) {
    print('${HomeScreen.routename} built');
    return Scaffold(
      appBar: AppBar(
        title: Text(HomeScreen.routename),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                // Authorize the app
                userId = await FitbitConnector.authorize(
                    context: context,
                    clientID: fitbitClientID,
                    clientSecret: fitbitClientSecret,
                    redirectUri: fitbitRedirectUri,
                    callbackUrlScheme: fitbitCallbackScheme);
                print("user id : " + userId.toString());
                prefs.setString('userId', userId!);

                //Instantiate a proper data manager
                FitbitActivityTimeseriesDataManager
                    fitbitActivityTimeseriesDataManager =
                    FitbitActivityTimeseriesDataManager(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                  type: 'distance',
                );

                //Fetch data
                final stepsData = await fitbitActivityTimeseriesDataManager
                    .fetch(FitbitActivityTimeseriesAPIURL.dayWithResource(
                  date: DateTime.now().subtract(const Duration(days: 1)),
                  userID: userId,
                  resource: fitbitActivityTimeseriesDataManager.type,
                )) as List<FitbitActivityTimeseriesData>;
                // Use them as you want
                final snackBar = SnackBar(
                    content: Text(
                        'Yesterday you walked ${stepsData[0].value} steps!'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: Text('Tap to authorize'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FitbitConnector.unauthorize(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                );
              },
              child: Text('Tap to unauthorize'),
            ),
            ElevatedButton(
              onPressed: () async {
                FitbitHeartDataManager fitbitHeartDataManager =
                    FitbitHeartDataManager(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                );
                FitbitHeartAPIURL fitbitHeartApiUrl =
                    FitbitHeartAPIURL.dayWithUserID(
                  date: DateTime.now(),
                  userID: userId,
                );
                List<FitbitData> fitbitHeartData =
                    await fitbitHeartDataManager.fetch(fitbitHeartApiUrl);
                print(fitbitHeartData.toString());
              },
              child: Text('Get Heart Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                FitbitSleepDataManager fitbitSleepDataManager =
                    FitbitSleepDataManager(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                );
                FitbitSleepAPIURL fitbitSleepAPIURL =
                    FitbitSleepAPIURL.withUserIDAndDay(
                  date: DateTime.now(),
                  userID: userId,
                );
                List<FitbitData> fitbitSleepdata =
                    await fitbitSleepDataManager.fetch(fitbitSleepAPIURL);
                print(fitbitSleepdata.toString());
              },
              child: Text('Get Sleep Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                FitbitDeviceDataManager fitbitDeviceDataManager =
                    FitbitDeviceDataManager(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                );
                FitbitDeviceAPIURL fitBitDeviceApiUrl =
                    FitbitDeviceAPIURL.withUserID(
                  userID: userId,
                );
                List<FitbitData> fitbitDeviceData =
                    await fitbitDeviceDataManager.fetch(fitBitDeviceApiUrl);
                for (FitbitData i in fitbitDeviceData) {
                  Map j = i.toJson();

                  var value = await http.get(Uri.parse(
                      'https://api.fitbit.com/' +
                          fitbitClientID.toString() +
                          '/user/' +
                          userId.toString() +
                          '/devices/tracker/' +
                          j['deviceId'] +
                          '/alarms.json'));
                  if (value.statusCode == 200) {
                    var jsonResponse =
                        convert.jsonDecode(value.body) as Map<String, dynamic>;
                    print(jsonResponse);
                  } else {
                    print('Request failed with status: ${value.statusCode}.');
                  }
                  print(value);
                }
              },
              child: Text('Get Alarm Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                FitbitActivityDataManager fitbitActivityDataManager =
                    FitbitActivityDataManager(
                  clientID: fitbitClientID,
                  clientSecret: fitbitClientSecret,
                );
                FitbitActivityAPIURL fitbitActivityURL =
                    FitbitActivityAPIURL.day(
                  userID: userId,
                  date: DateTime.now(),
                );
                var fitbitActivityData = await fitbitActivityDataManager
                    .getResponse(fitbitActivityURL);
                print(fitbitActivityData.toString());
              },
              child: Text('Get Acivity Data'),
            ),
          ],
        ),
      ),
    );
  }
}
