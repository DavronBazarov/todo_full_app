import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../widgets/bottom_navbar_widget.dart';
import '../widgets/fab_widget.dart';
import '../widgets/quote_widget.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/top_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String formattedTime = DateFormat.Hm().format(DateTime.now());
  TimeOfDay? disTime;
  var finalTime;
  DateTime? disDate;
  Future<void> _refreshProduct(BuildContext context) async {
    await Provider.of<TaskProvider>(context, listen: false).getAllTask();
  }
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<TaskProvider>(context, listen: false);
    provider.getAllTask();
    provider.sortTaskByDate(provider.objectOfSelectedDate);
    //  provider.deleteOldTasks();

    return Scaffold(
      // extendBody: true,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const FABWidget(),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.18,
              width: double.infinity,
              alignment: Alignment.topCenter,
              decoration: const BoxDecoration(
                // color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 1),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: TopCardWithDate(
                        topCardColor: Colors.white,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TaskCard(
                        cardName: 'Top Priority',
                        cardSideColor: const Color(0xffee4266),
                        cardMaxColor: Colors.lime[50]!,
                        isImp: true,
                        placeholderWidget: const QuoteWidget(
                          quote: '"You May Delay, But Time Will Not." ',
                          quoteBy: '-Davron Bazarov',
                          fontsize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: TaskCard(
                        cardName: 'Other Tasks',
                        cardSideColor: const Color(0xff0b3866),
                        cardMaxColor: Colors.lime[50]!,
                        isImp: false,
                        placeholderWidget: const QuoteWidget(
                            quote: '"A Goal Without A Plan Is Just A Wish."',
                            quoteBy: '-Davron Bazarov',
                            fontsize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              height: 50,
              width: 50,
              bottom: 30,
              right: 30,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                   await _refreshProduct(context);
                    setState(() {
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 40,),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
