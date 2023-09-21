import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '/constants.dart';
import '/main.dart';
import '/model/CurrencyModel.dart';
import '/model/User.dart';
import '/services/FirebaseHelper.dart';
import '/services/helper.dart';
import '/ui/Language/language_choose_screen.dart';
import '/ui/auth/AuthScreen.dart';
import '/ui/bank_details/bank_details_Screen.dart';
import '/ui/chat_screen/inbox_screen.dart';
import '/ui/home/HomeScreen.dart';
import '/ui/ordersScreen/OrdersScreen.dart';
import '/ui/privacy_policy/privacy_policy.dart';
import '/ui/profile/ProfileScreen.dart';
import '/ui/termsAndCondition/terms_and_codition.dart';
import '/ui/wallet/walletScreen.dart';
import '/userPrefrence.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

enum DrawerSelection {
  Home,
  Cuisines,
  Search,
  Cart,
  Profile,
  Orders,
  Logout,
  Wallet,
  BankInfo,
  inbox,
  termsCondition,
  privacyPolicy,
  chooseLanguage,
}

class ContainerScreen extends StatefulWidget {
  final User user;

  ContainerScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _ContainerScreen createState() {
    return _ContainerScreen();
  }
}

class _ContainerScreen extends State<ContainerScreen> {
  late User user;
  String _appBarTitle = 'Home'.tr();
  final fireStoreUtils = FireStoreUtils();
  late Widget _currentWidget;
  DrawerSelection _drawerSelection = DrawerSelection.Home;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _currentWidget = HomeScreen();
    setCurrency();
    updateCurrentLocation();

    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    getplaceholderimage();
  }

  setCurrency() async {
    await FireStoreUtils().getCurrency().then((value) {
      if (value != null) {
        currencyModel = value;
      } else {
        currencyModel = CurrencyModel(id: "", code: "USD", decimal: 2, isactive: true, name: "US Dollar", symbol: "\$", symbolatright: false);
      }
      setState(() {});
    });

    await FireStoreUtils().getRazorPayDemo();
    await FireStoreUtils.getPaypalSettingData();
    await FireStoreUtils.getStripeSettingData();
    await FireStoreUtils.getPayStackSettingData();
    await FireStoreUtils.getFlutterWaveSettingData();
    await FireStoreUtils.getPaytmSettingData();
    await FireStoreUtils.getWalletSettingData();
    await FireStoreUtils.getPayFastSettingData();
    await FireStoreUtils.getMercadoPagoSettingData();
    await FireStoreUtils.getReferralAmount();
  }

  Future<String?> getplaceholderimage() async {
    var collection = FirebaseFirestore.instance.collection(Setting);
    var docSnapshot = await collection.doc('placeHolderImage').get();
    Map<String, dynamic>? data = docSnapshot.data();
    var value = data?['image'];
    placeholderImage = value;
    return placeholderImage;
  }

  DateTime preBackpress = DateTime.now();

  final audioPlayer = AudioPlayer(playerId: "playerId");
  Location location = Location();

  updateCurrentLocation() async {
    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.granted) {
      location.enableBackgroundMode(enable: true);
      location.changeSettings(accuracy: LocationAccuracy.navigation, distanceFilter: 3);
      location.onLocationChanged.listen((locationData) async {
        locationDataFinal = locationData;
        await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value) {
          if (value != null) {
            User driverUserModel = value;
            if (driverUserModel.isActive == true) {
              driverUserModel.location = UserLocation(latitude: locationData.latitude ?? 0.0, longitude: locationData.longitude ?? 0.0);
              driverUserModel.rotation = locationData.heading;
              FireStoreUtils.updateCurrentUser(driverUserModel);
            }
          }
        });
      });
    } else {
      location.requestPermission().then((permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          location.enableBackgroundMode(enable: true);
          location.changeSettings(accuracy: LocationAccuracy.navigation, distanceFilter: 3);
          location.onLocationChanged.listen((locationData) async {
            locationDataFinal = locationData;
            await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value) {
              if (value != null) {
                User driverUserModel = value;
                if (driverUserModel.isActive == true) {
                  driverUserModel.location = UserLocation(latitude: locationData.latitude ?? 0.0, longitude: locationData.longitude ?? 0.0);
                  driverUserModel.rotation = locationData.heading;
                  FireStoreUtils.updateCurrentUser(driverUserModel);
                }
              }
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final timegap = DateTime.now().difference(preBackpress);
        final cantExit = timegap >= Duration(seconds: 2);
        preBackpress = DateTime.now();
        if (cantExit) {
          //show snackbar
          final snack = SnackBar(
            content: Text(
              'Press Back button again to Exit'.tr(),
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
          return false; // false will do nothing when back press
        } else {
          return true; // true will exit the app
        }
      },
      child: ChangeNotifierProvider.value(
        value: user,
        child: Consumer<User>(
          builder: (context, user, _) {
            return Scaffold(
              drawer: Drawer(
                backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Consumer<User>(builder: (context, user, _) {
                      return DrawerHeader(
                        margin: EdgeInsets.all(0.0),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            displayCircleImage(user.profilePictureURL, 60, false),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                user.fullName(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(color: Colors.white),
                            ),
                            SwitchListTile(
                              visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "Online",
                                style: TextStyle(color: Colors.white),
                              ),
                              // thumb color (round icon)
                              value: user.isActive,
                              onChanged: (value) {
                                setState(() {
                                  user.isActive = value;
                                });

                                if(user.isActive == true){
                                  updateCurrentLocation();
                                }
                                FireStoreUtils.updateCurrentUser(user);
                              },
                            ),
                          ],
                        ),
                        decoration: BoxDecoration(
                          color: Color(COLOR_PRIMARY),
                        ),
                      );
                    }),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.Home,
                        title: Text('Home').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.Home;
                            _appBarTitle = 'Home'.tr();
                            _currentWidget = HomeScreen();
                          });
                        },
                        leading: Icon(CupertinoIcons.home),
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.Orders,
                        leading: Image.asset(
                          'assets/images/truck.png',
                          color: _drawerSelection == DrawerSelection.Orders
                              ? Color(COLOR_PRIMARY)
                              : isDarkMode(context)
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade600,
                          width: 24,
                          height: 24,
                        ),
                        title: Text('Órdenes').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.Orders;
                            _appBarTitle = 'Orders'.tr();
                            _currentWidget = OrdersScreen();
                          });
                        },
                      ),
                    ),
                    Visibility(
                      visible: UserPreference.getWalletData() ?? false,
                      child: ListTileTheme(
                        style: ListTileStyle.drawer,
                        selectedColor: Color(COLOR_PRIMARY),
                        child: ListTile(
                          selected: _drawerSelection == DrawerSelection.Wallet,
                          leading: Icon(Icons.account_balance_wallet_sharp),
                          title: Text('Wallet').tr(),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _drawerSelection = DrawerSelection.Wallet;
                              _appBarTitle = 'Earnings'.tr();
                              _currentWidget = WalletScreen();
                            });
                          },
                        ),
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.BankInfo,
                        leading: Icon(Icons.account_balance),
                        title: Text('Detalles de banco').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.BankInfo;
                            _appBarTitle = 'Bank Info'.tr();
                            _currentWidget = BankDetailsScreen();
                          });
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.Profile,
                        leading: Icon(CupertinoIcons.person),
                        title: Text('Perfil').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.Profile;
                            _appBarTitle = 'Mi perfil'.tr();
                            _currentWidget = ProfileScreen(
                              user: user,
                            );
                          });
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.chooseLanguage,
                        leading: Icon(
                          Icons.language,
                          color: _drawerSelection == DrawerSelection.chooseLanguage
                              ? Color(COLOR_PRIMARY)
                              : isDarkMode(context)
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade600,
                        ),
                        title: const Text('Language').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.chooseLanguage;
                            _appBarTitle = 'Lenguaje'.tr();
                            _currentWidget = LanguageChooseScreen(
                              isContainer: true,
                            );
                          });
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.inbox,
                        leading: Icon(CupertinoIcons.chat_bubble_2_fill),
                        title: Text('Inbox').tr(),
                        onTap: () {
                          if (MyAppState.currentUser == null) {
                            Navigator.pop(context);
                            push(context, AuthScreen());
                          } else {
                            Navigator.pop(context);
                            setState(() {
                              _drawerSelection = DrawerSelection.inbox;
                              _appBarTitle = 'My Inbox'.tr();
                              _currentWidget = InboxScreen();
                            });
                          }
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.termsCondition,
                        leading: const Icon(Icons.policy),
                        title: const Text('Términos y condiciones').tr(),
                        onTap: () async {
                          push(context, const TermsAndCondition());
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.privacyPolicy,
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Política de privacidad').tr(),
                        onTap: () async {
                          push(context, const PrivacyPolicyScreen());
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.Logout,
                        leading: Icon(Icons.logout),
                        title: Text('Salir de la sesión').tr(),
                        onTap: () async {
                          audioPlayer.stop();
                          Navigator.pop(context);
                          user.isActive = false;
                          user.lastOnlineTimestamp = Timestamp.now();
                          await FireStoreUtils.updateCurrentUser(user);
                          await auth.FirebaseAuth.instance.signOut();
                          MyAppState.currentUser = null;
                          pushAndRemoveUntil(context, AuthScreen(), false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              appBar: AppBar(
                iconTheme: IconThemeData(
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                centerTitle: _drawerSelection == DrawerSelection.Wallet ? true : false,
                backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white,
                title: Text(
                  _appBarTitle,
                  style: TextStyle(
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                ),
              ),
              body: _currentWidget,
            );
          },
        ),
      ),
    );
  }
}
