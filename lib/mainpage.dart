import 'package:flutter/material.dart';
import 'package:namer_app/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'datausage.dart';

Map<String, dynamic> currentTask = {};
String Username = '';
String responseBody = '';
String WeekPlanName = '';
List<dynamic> currentweek = [];

Future<String> getPatientID() async {
  // Define the URL for the endpoint
  String url = 'https://server---app-d244e2f2d7c9.herokuapp.com/getPatientID/';

  try {
    // Send the HTTP GET request with the username as a query parameter
    http.Response response =
        await http.get(Uri.parse('$url?userName=$Username'));

    if (response.statusCode == 200) {
      // If the request is successful, return the patient ID from the response body
      return response.body;
    } else if (response.statusCode == 404) {
      // If no user or file found, return null
      print('No user or file found.');
      return '';
    } else {
      // If an error occurred, print the status code and return null
      print('Error: ${response.statusCode}');
      return '';
    }
  } catch (error) {
    // If an error occurred making the HTTP request, print the error and return null
    print('Error: $error');
    return '';
  }
}

Future<String> getPatientFile() async {
  String patientIDWithSpecialChars = await getPatientID();
  String pID = patientIDWithSpecialChars.split('%')[0];
  String url =
      'https://server---app-d244e2f2d7c9.herokuapp.com/getPatientFile/';

  try {
    http.Response response = await http.get(Uri.parse('$url?pID=$pID'));

    if (response.statusCode == 200) {
      // If the request is successful, return the patient file from the response body
      return response.body;
    } else if (response.statusCode == 404) {
      // If no user or file found, return null
      print('No user or file found.');
      return '';
    } else {
      // If an error occurred, print the status code and return null
      print('Error: ${response.statusCode}');
      return '';
    }
  } catch (error) {
    // If an error occurred making the HTTP request, print the error and return null
    print('Error: $error');
    return '';
  }
}

class MyData {
  final String dayName;
  final double dayProgress;

  MyData(this.dayName, this.dayProgress);
}

class MainPage extends StatefulWidget {
  final String username;

  const MainPage({Key? key, required this.username}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState(username: username);
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages = [];

  final String username;

  _MainPageState({required this.username});

  @override
  void initState() {
    super.initState();
    getUsernameAndPatientFile();
  }

  Future<void> getUsernameAndPatientFile() async {
    Username = username;
    responseBody = await getPatientFile();
    setState(() {
      _pages = [
        WelcomePage(),
        Page1(),
        Page2(),
        Page3(),
        Page4(),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return CircularProgressIndicator();
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            'Monitor',
            style: TextStyle(
              color: Colors.white, // Set text color to white
            ),
          ),
          leading: null, // Remove the back arrow icon

          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 24, 81, 128),
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              buildListTile('ThisWeek', 0),
              buildListTile('Chat', 1),
              buildListTile('Focus', 2),
              buildListTile('User Activity', 3),
              buildListTile('Setting', 4),
              buildListTile('logout', 5),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: _pages[_selectedIndex],
        ),
      );
    }
  }

  Widget buildListTile(String title, int index) {
    return InkWell(
      onTap: () {
        if (index == 5) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          _onItemTapped(index);
          Navigator.pop(context);
        }
      },
      splashColor: Color.fromARGB(255, 24, 81, 128)
          .withOpacity(0.5), // Customize the splash color
      borderRadius: BorderRadius.circular(10), // Customize the border radius
      child: ListTile(
        title: Text(title),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  String removeControlCharacters() {
    RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
    return responseBody.replaceAll(controlCharactersRegex, '');
  }

  String getName() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['patientName'];
    } catch (e) {
      // Handle parsing errors
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  List<String> getRange() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());

      // Check if 'plans' array exists and is not empty
      if (response.containsKey('plans') &&
          response['plans'] != null &&
          response['plans'].isNotEmpty) {
        // Current date
        DateTime currentDate = DateTime.now();

        // Iterate over each plan
        for (var plan in response['plans']) {
          String startDateString = plan['weekPlanSDate'];
          String endDateString = plan['weekPlanEDate'];

          // Parse start and end dates
          List<String> startDateParts =
              (plan['weekPlanSDate'] as String).split('/');
          DateTime planStartDate = DateTime(
            int.parse(startDateParts[2]),
            int.parse(startDateParts[1]),
            int.parse(startDateParts[0]),
          );
          List<String> endDateParts =
              (plan['weekPlanEDate'] as String).split('/');
          DateTime planEndDate = DateTime(
            int.parse(endDateParts[2]),
            int.parse(endDateParts[1]),
            int.parse(endDateParts[0]),
          );

          if (currentDate.year == planStartDate.year &&
                  currentDate.month == planStartDate.month &&
                  currentDate.day == planStartDate.day ||
              currentDate.year == planEndDate.year &&
                  currentDate.month == planEndDate.month &&
                  currentDate.day == planEndDate.day ||
              (currentDate.isAfter(planStartDate) &&
                  currentDate.isBefore(planEndDate))) {
            return [startDateString, endDateString];
          }
        }

        return ['', ''];
      } else {
        return ['', ''];
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      return ['Error', 'Error'];
    }
  }

  @override
  Widget build(BuildContext context) {
    String patientName = getName();
    List<String> date = getRange();
    String start = date[0];
    String end = date[1];

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 35), // Adjust the value as needed
          child: Text(
            'Welcome Back : $patientName',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: DefaultTabController(
        length: 7, // Number of days in a week
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10),
            ),
            TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white, // Set text color to white

              tabs: [
                Tab(text: 'Monday'),
                Tab(text: 'Tuesday'),
                Tab(text: 'Wednesday'),
                Tab(text: 'Thursday'),
                Tab(text: 'Friday'),
                Tab(text: 'Saturday'),
                Tab(text: 'Sunday'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDayBlock('Monday'),
                  _buildDayBlock('Tuesday'),
                  _buildDayBlock('Wednesday'),
                  _buildDayBlock('Thursday'),
                  _buildDayBlock('Friday'),
                  _buildDayBlock('Saturday'),
                  _buildDayBlock('Sunday'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//To Do Specify the intended Week
  Widget _buildDayBlock(String day) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(removeControlCharacters());
      List<dynamic> plans = jsonData['plans'];
      Map<String, dynamic> dayPlan = {};
      DateTime currentDate = DateTime.now();

      if (plans == null || plans.isEmpty) {
        return _buildNoDataWidget();
      }
      for (var plan in plans) {
        List<String> startDateParts =
            (plan['weekPlanSDate'] as String).split('/');
        DateTime planStartDate = DateTime(
          int.parse(startDateParts[2]),
          int.parse(startDateParts[1]),
          int.parse(startDateParts[0]),
        );
        List<String> endDateParts =
            (plan['weekPlanEDate'] as String).split('/');
        DateTime planEndDate = DateTime(
          int.parse(endDateParts[2]),
          int.parse(endDateParts[1]),
          int.parse(endDateParts[0]),
        );
        if (currentDate.year == planStartDate.year &&
                currentDate.month == planStartDate.month &&
                currentDate.day == planStartDate.day ||
            currentDate.year == planEndDate.year &&
                currentDate.month == planEndDate.month &&
                currentDate.day == planEndDate.day ||
            (currentDate.isAfter(planStartDate) &&
                currentDate.isBefore(planEndDate))) {
          var weekPlan = plan['weekPlan'];
          currentweek = plan['weekPlan'];
          WeekPlanName = plan['weekPlanName'];

          for (var dayPlanData in weekPlan) {
            if (dayPlanData['dayName'] == day) {
              dayPlan = dayPlanData;
              break;
            }
          }
          if (dayPlan.isNotEmpty) {
            break;
          }
        }

        if (dayPlan.isEmpty) {
          continue;
        } else {
          print(
              'Plan ${plan['weekPlanName']} has already ended. Proceeding to the next plan...');
          continue;
        }
      }

      List<dynamic> tasks = dayPlan['tasks'];

      return Expanded(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Color.fromARGB(255, 24, 81, 128),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 24, 81, 128),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 16, 63, 102),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 100,
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Column(
                    children: tasks.map<Widget>((task) {
                      bool isDone = task['submitted'] == 'true';
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color.fromARGB(255, 16, 63, 102)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TaskItem(
                              task: task['taskName'],
                              isDone: isDone,
                              taskData: task,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error parsing JSON: $e');
      return SizedBox.shrink();
    }
  }
}

Widget _buildNoDataWidget() {
  final ScrollController _scrollController = ScrollController();

  return Scrollbar(
    controller: _scrollController,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Color.fromARGB(255, 24, 81, 128),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                // Wrap child with Container
                width: 200, // Set fixed width
                child: Text(
                  'No Tasks This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 16, 63, 102),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class TaskItem extends StatefulWidget {
  final String task;
  final bool isDone;
  final Map<String, dynamic> taskData;

  const TaskItem({
    Key? key,
    required this.task,
    this.isDone = false,
    required this.taskData,
  }) : super(key: key);

  @override
  _TaskItemState createState() => _TaskItemState(taskData: taskData);
}

class _TaskItemState extends State<TaskItem> {
  bool _isHovered = false;
  final Map<String, dynamic> taskData;
  bool TaskRunning = false;
  String CurrentTask = '';

  _TaskItemState({required this.taskData});

  String getname() {
    return taskData['taskName'];
  }

  Map<String, dynamic> getTaskData() {
    return taskData;
  }

  String getST() {
    return taskData['startTime'];
  }

  String getET() {
    return taskData['endTime'];
  }

  String getDesc() {
    return taskData['description'];
  }

  String duration() {
    return taskData['taskDuration'];
  }

  String taskReview() {
    return taskData['Review'];
  }

  String Prog() {
    return taskData['taskProgress'];
  }

  String SubPer() {
    return taskData['submittedPercentage'];
  }

  String PercOfD() {
    return taskData['percentageOfDay'];
  }

  List<dynamic> Programs() {
    return taskData['programs'];
  }

  void setTaskRunning(bool t) {
    TaskRunning = t;
  }

  String getCT() {
    return CurrentTask;
  }

  bool currentDay(String taskName) {
    List<Map<String, dynamic>> currentweekList =
        currentweek.cast<Map<String, dynamic>>();

    Map<String, dynamic> currentweekMap = {};
    currentweekList.forEach((dayData) {
      currentweekMap[dayData['dayName']] = dayData['tasks'];
    });

    String currentDayName = DateFormat('EEEE').format(DateTime.now());
    List<dynamic>? tasksForCurrentDay = currentweekMap[currentDayName];
    List<String> taskNames = tasksForCurrentDay != null
        ? tasksForCurrentDay.map((task) => task['taskName'] as String).toList()
        : [];

    if (taskNames.contains(taskName)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    String taskName = getname();
    String startTime = getST();
    String endTime = getET();
    String description = getDesc();
    String taskDuration = duration();
    String taskProgress = Prog();
    String submittedPercentage = SubPer();
    String percentageOfDay = PercOfD();
    List<dynamic> programs = Programs();
    String taskDataJson = jsonEncode(taskData);
    Map<String, dynamic> data = taskData;

    String programNames = '';
    for (var program in programs) {
      String baseName = program['baseName'];
      programNames += '$baseName, '; // Concatenate each name
    }

    programNames = programNames.isNotEmpty
        ? programNames.substring(0, programNames.length - 2)
        : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isDone ? Icons.check : Icons.close,
                color: widget.isDone
                    ? Color.fromARGB(255, 24, 81, 128)
                    : Color.fromARGB(255, 24, 81, 128),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: AlertDialog(
                          title: Center(
                            child: Text(
                              'Task Details',
                              style: TextStyle(
                                color: Color.fromARGB(
                                    255, 16, 63, 102), // Change the color here
                              ),
                            ),
                          ),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Task Name',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $taskName',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Start Time',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $startTime',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'End Time',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $endTime',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $description',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Task Duration',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $taskDuration',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Task Progress',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $taskProgress',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Submitted Percentage',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $submittedPercentage',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Programs',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 16, 63, 102)),
                                    ),
                                    TextSpan(
                                      text: ': $programNames',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            if (!widget.isDone)
                              TextButton(
                                onPressed: () {
                                  if (currentDay(taskName)) {
                                    if (currentTask.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Task has started. Check User Activity for Running Task',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      currentTask = data;
                                      Navigator.of(context).pop();
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'There is a Task Running',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'The Task Running Is not For Today',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  'Start Task',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 24, 81, 128),
                                  ),
                                ),
                              ),
                            if (!widget.isDone)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close',
                                    style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  widget.task,
                  style: TextStyle(
                    fontSize: 20,
                    color: _isHovered
                        ? Colors.green
                        : Color.fromARGB(255, 24, 81, 128),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Page1 extends StatefulWidget {
  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  List<ChatMessage> messages = [];
  Timer? timer;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getChat();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      getChat();
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer in dispose
    super.dispose();
  }

  void getChat() async {
    String C = getCname();
    String P = getName();
    String url = 'https://server---app-d244e2f2d7c9.herokuapp.com/getChat/';

    try {
      http.Response response =
          await http.get(Uri.parse('$url?patientName=$P&coachName=$C'));

      if (response.statusCode == 200) {
        String responseBody = response.body;
        if (responseBody.isNotEmpty) {
          List<dynamic> responseBodyChat = json.decode(responseBody);
          Map<String, dynamic> inboxData = responseBodyChat[0];
          List<dynamic> inbox = inboxData['inbox'];
          List<ChatMessage> fetchedMessages = [];

          // Iterate over each message in the inbox
          for (var messageData in inbox) {
            // Assuming each messageData is a String
            String messageString = messageData;

            // Split the message string to extract sender and text
            List<String> parts = messageString.split(':');

            // Extract sender and text
            String sender = parts[0].trim();
            String text = parts[1].trim();

            fetchedMessages.add(ChatMessage(sender: sender, text: text));
          }

          // Clear the existing messages before adding the new ones
          if (!mounted) return; // Check if the widget is still mounted
          setState(() {
            messages.clear();
            messages.addAll(fetchedMessages);
          });
        } else {
          // Display a message indicating no messages available
          setState(() {
            messages.clear();
          });
        }
      } else if (response.statusCode == 404) {
        print('No user or file found.');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void sendChat(String message) async {
    String C = getCname();
    String P = getName();
    String url =
        'https://server---app-d244e2f2d7c9.herokuapp.com/sendMassegeP/';
    try {
      http.Response response = await http.post(
        Uri.parse('$url?patientName=$P&coachName=$C&message=$message'),
      );

      if (response.statusCode == 200) {
        print('Success');
      } else if (response.statusCode == 404) {
        print('No user or file found.');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  String removeControlCharacters() {
    RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
    return responseBody.replaceAll(controlCharactersRegex, '');
  }

  String getName() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['patientName'];
    } catch (e) {
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  String getCname() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['coachName'];
    } catch (e) {
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Chat'),
        leading: null, // Remove the back arrow icon
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                for (var message in messages)
                  ChatMessage(
                    sender: message.sender,
                    text: message.text,
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    String message = _messageController.text;
                    if (message.isNotEmpty) {
                      sendChat(message);
                      getChat();
                      _messageController
                          .clear(); // Clear the text field after sending the message
                      setState(
                          () {}); // Update the UI to reflect the new messages
                    } else {
                      // Show an error message or handle empty message case
                    }
                  },
                  child: Text(
                    'Send',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String sender;
  final String text;

  const ChatMessage({Key? key, required this.sender, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 24, 81, 128),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                sender,
                style: TextStyle(
                  color: Color.fromARGB(255, 24, 81, 128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                displayFormattedCallLog(context);
              },
              child: Text('Show Call Logs'),
            ),
            ElevatedButton(
              onPressed: () async {
                String locationData =
                    await UsageStatsManager.getLocationUpdates();
                _showLocationDialog(context, locationData);
              },
              child: Text('Show Location'),
            ),
            ElevatedButton(
              onPressed: () async {
                String locationData =
                    await UsageStatsManager.getLocationUpdates();
                _showLocationDialog(context, locationData);
              },
              child: Text(' Activity '),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Map<String, int>>(
            future: UsageStatsManager.getDailyAppUsageStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While data is being fetched, display a loading indicator
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                Map<String, int> data = snapshot.data!;

                List<Widget> appUsageWidgets = [];

                data.forEach((appName, usageDuration) {
                  appUsageWidgets.add(
                    ListTile(
                      title: Text(appName),
                      subtitle: Text(
                          'Usage Duration: ${_formatDuration(usageDuration)}'),
                    ),
                  );
                });

                return ListView(
                  children: appUsageWidgets,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(int durationInSeconds) {
    int hours = durationInSeconds ~/ 3600;
    int minutes = (durationInSeconds % 3600) ~/ 60;
    return '$hours hours $minutes minutes';
  }

  void _showLocationDialog(BuildContext context, String locationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Data'),
          content: Text(locationData),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void displayFormattedCallLog(BuildContext context) async {
    String formattedEntry = await UsageStatsManager.formatCallLogEntry();

    // Show dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Calls'),
          content: Text(formattedEntry),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class Page2LockApp extends StatefulWidget {
  @override
  _Page2LockAppState createState() => _Page2LockAppState();
}

class _Page2LockAppState extends State<Page2LockApp> {
  bool isLocked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lock App',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 24, 81, 128),
                shadows: [
                  Shadow(
                    color: Color.fromARGB(255, 24, 81, 128).withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ]),
          ),
          SizedBox(height: 20),
          Switch(
            value: isLocked,
            onChanged: (value) {
              setState(() {
                isLocked = value;
              });
            },
            activeColor: Colors.cyan,
          ),
          Text(
            isLocked ? 'App is Locked' : 'App is Unlocked',
            style: TextStyle(
              fontSize: 18,
              color: isLocked ? Colors.red : Color.fromARGB(255, 24, 81, 128),
            ),
          ),
        ],
      ),
    );
  }
}

class Page2Reminders extends StatefulWidget {
  @override
  _Page2RemindersState createState() => _Page2RemindersState();
}

class _Page2RemindersState extends State<Page2Reminders> {
  bool remindersEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Reminders',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 24, 81, 128),
                shadows: [
                  Shadow(
                    color: Color.fromARGB(255, 24, 81, 128).withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ]),
          ),
          SizedBox(height: 20),
          Switch(
            value: remindersEnabled,
            onChanged: (value) {
              setState(() {
                remindersEnabled = value;
              });
            },
            activeColor: Colors.cyan,
          ),
          Text(
            remindersEnabled ? 'Reminders Enabled' : 'Reminders Disabled',
            style: TextStyle(
              fontSize: 18,
              color: remindersEnabled
                  ? Color.fromARGB(255, 24, 81, 128)
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class Page3 extends StatefulWidget {
  @override
  _Page3State createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  late Timer _timer;
  late Timer _dialogTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isDialogShown = false;

  _Page3State();

  @override
  void initState() {
    super.initState();
  }

  List<List<dynamic>> getWeekPlan() {
    List<List<dynamic>> weekPlans = [];
    try {
      Map<String, dynamic> jsonData = jsonDecode(removeControlCharacters());
      List<dynamic> plans = jsonData['plans'];
      DateTime currentDate = DateTime.now();

      for (var plan in plans) {
        List<String> startDateParts =
            (plan['weekPlanSDate'] as String).split('/');
        DateTime planStartDate = DateTime(
          int.parse(startDateParts[2]),
          int.parse(startDateParts[1]),
          int.parse(startDateParts[0]),
        );

        List<String> endDateParts =
            (plan['weekPlanEDate'] as String).split('/');
        DateTime planEndDate = DateTime(
          int.parse(endDateParts[2]),
          int.parse(endDateParts[1]),
          int.parse(endDateParts[0]),
        );

        // Check if the current date is within the date range of the plan
        if (currentDate.year == planStartDate.year &&
                currentDate.month == planStartDate.month &&
                currentDate.day == planStartDate.day ||
            currentDate.year == planEndDate.year &&
                currentDate.month == planEndDate.month &&
                currentDate.day == planEndDate.day ||
            (currentDate.isAfter(planStartDate) &&
                currentDate.isBefore(planEndDate))) {
          var weekPlan = plan['weekPlan'];
          for (var day in weekPlan) {
            weekPlans.add([day['dayName'], day['dayProgress']]);
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
    return weekPlans;
  }

  List<dynamic> getWeekPlans() {
    List<dynamic> plans = [];
    try {
      Map<String, dynamic> jsonData = jsonDecode(removeControlCharacters());
      plans = jsonData['plans'].map((plan) {
        String name = plan['weekPlanName'];
        List<dynamic> dayProgress = [];
        List<dynamic> weekPlan = plan['weekPlan'];
        for (var day in weekPlan) {
          dayProgress.add(day['dayProgress']);
        }
        return [name, dayProgress];
      }).toList();
    } catch (e) {
      print('Error: $e');
    }
    return plans;
  }

  List<dynamic> calculateAverageTotalDayProgress(List<dynamic> weekPlans) {
    List<double> totalProgress = List.filled(7, 0.0);
    List<String> names = [];

    for (var plan in weekPlans) {
      String name = plan[0];
      List<dynamic> daysProgress =
          plan[1].map((value) => double.parse(value)).toList();

      names.add(name);

      for (int i = 0; i < daysProgress.length; i++) {
        totalProgress[i] += daysProgress[i];
      }
    }
    return [names, totalProgress];
  }

  String removeControlCharacters() {
    RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
    return responseBody.replaceAll(controlCharactersRegex, '');
  }

  @override
  void dispose() {
    _timer.cancel();
    _dialogTimer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _startTimerNotify();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isTimerRunning) {
        setState(() {
          _elapsedSeconds++;

          if (_elapsedSeconds == int.parse(currentTask['taskDuration']) * 60) {
            timer.cancel();
            _dialogTimer.cancel(); // Cancel dialog timer when main timer ends
          }
        });
      }
    });
  }

  void _startTimerNotify() {
    _dialogTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (!_isTimerRunning && !_isDialogShown) {
        _isDialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Are you currently doing the task?"),
              content: Text("This message will disappear in 1 minute."),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    _isDialogShown = false;
                    Navigator.of(context).pop(true);
                  },
                  child: Text("Yes"),
                ),
              ],
            );
          },
        ).then((result) {
          if (result == true) {
            return;
          } else {
            _timer.cancel();
            _dialogTimer.cancel();
            Navigator.of(context).pop(true);
          }
        });
      }
    });
  }

  void showTotalPerformanceProgressChartDialog(List<dynamic> weekplan) {
    List<FlSpot> seriesList = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), 0),
    );
    List<double> average = weekplan[1].cast<double>();

    try {
      for (int i = 0; i < average.length; i++) {
        double dayProgress = double.tryParse(average[i].toString()) ?? 0.0;
        seriesList[i] = FlSpot(i.toDouble(), dayProgress);
      }
    } catch (e) {
      print('Error: $e');
    }

    List<String> dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Total Overall Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 24, 81, 128),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 300, // Adjust container height
                  child: LineChart(
                    LineChartData(
                      minY: 0, // Adjust y-axis minimum value
                      maxY: 100, // Adjust y-axis maximum value
                      lineBarsData: [
                        LineChartBarData(
                          spots: seriesList,
                          isCurved: true,
                          colors: [Colors.orange],
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 20,
                          rotateAngle: 45,
                          getTitles: (value) {
                            // Customizing X-axis labels using the predefined day names list
                            if (value % 1 == 0) {
                              return dayNames[value
                                  .toInt()]; // Return the day name corresponding to the index
                            }
                            return '';
                          },
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 8, // Adjust margin for y-axis labels
                          reservedSize:
                              30, // Adjust the space reserved for y-axis labels
                          interval:
                              10, // Define the interval between y-axis labels
                          getTitles: (value) {
                            return value
                                .toInt()
                                .toString(); // Convert value to string
                          },
                        ),
                        rightTitles: SideTitles(
                            showTitles: false), // Hide right y-axis labels
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 24, 81, 128),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showProgressChartDialog(dynamic weekplan) {
    List<FlSpot> seriesList = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), 0),
    );
    try {
      for (int i = 0; i < weekplan.length; i++) {
        double dayProgress = double.tryParse(weekplan[i][1].toString()) ?? 0.0;
        seriesList[i] = FlSpot(i.toDouble(), dayProgress);
      }
    } catch (e) {
      print('Error: $e');
    }

    List<String> dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Total Week Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 24, 81, 128),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 300, // Adjust container height
                  child: LineChart(
                    LineChartData(
                      minY: 0, // Adjust y-axis minimum value
                      maxY: 100, // Adjust y-axis maximum value
                      lineBarsData: [
                        LineChartBarData(
                          spots: seriesList,
                          isCurved: true,
                          colors: [Color.fromARGB(255, 24, 81, 128)],
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 20,
                          rotateAngle: 45,
                          getTitles: (value) {
                            // Customizing X-axis labels using the predefined day names list
                            if (value % 1 == 0) {
                              return dayNames[value
                                  .toInt()]; // Return the day name corresponding to the index
                            }
                            return '';
                          },
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 8, // Adjust margin for y-axis labels
                          reservedSize:
                              30, // Adjust the space reserved for y-axis labels
                          interval:
                              10, // Define the interval between y-axis labels
                          getTitles: (value) {
                            return value
                                .toInt()
                                .toString(); // Convert value to string
                          },
                        ),
                        rightTitles: SideTitles(
                            showTitles: false), // Hide right y-axis labels
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 24, 81, 128),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    List<List<dynamic>> weekplan = getWeekPlan();
    List<dynamic> plans = getWeekPlans();

    if (currentTask.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'No Tasks Running Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  showProgressChartDialog(weekplan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 24, 81, 128),
                  elevation: 5,
                ),
                child: Text(
                  'Total Week \n Performance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  showTotalPerformanceProgressChartDialog(
                      calculateAverageTotalDayProgress(plans));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 24, 81, 128),
                  elevation: 5,
                ),
                child: Text(
                  'Total Performance',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    String taskName = currentTask['taskName'];
    String startTime = currentTask['startTime'];
    String endTime = currentTask['endTime'];
    String description = currentTask['description'];
    int totalDuration = int.parse(currentTask["taskDuration"]);
    int remainingDuration = (totalDuration * 60 - _elapsedSeconds) ~/ 60;
    String duration = remainingDuration.toString();
    List<dynamic> programs = currentTask['programs'];
    String programNames = '';
    for (var program in programs) {
      String baseName = program['baseName'];
      programNames += '$baseName, '; // Concatenate each name
    }

    programNames = programNames.isNotEmpty
        ? programNames.substring(0, programNames.length - 2)
        : '';
    return Column(
      children: [
        Container(
          height: screenSize.height * 0.5, // Adjusted height for Block One
          margin: EdgeInsets.all(10), // Add margin for spacing
          decoration: BoxDecoration(
            color: Colors.white, // Change background color to white
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Color.fromARGB(255, 24, 81, 128),
                width: 3), // Add border color
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 24, 81, 128).withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(10), // Add padding for spacing
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Text(
                    'Current Task: $taskName ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 24, 81, 128),
                    ),
                  ),
                  SizedBox(width: 100), // Add space between texts
                  SubmitTask()
                ]),
                Row(
                  children: [
                    Text(
                      'Start Time: $startTime',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 24, 81, 128),
                      ),
                    ),
                    SizedBox(width: 75), // Add space between texts
                    Text(
                      ' Exp EndTime: $endTime',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 24, 81, 128),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Description: $description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 24, 81, 128),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Duration:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 24, 81, 128),
                      ),
                    ),
                    SizedBox(width: 5),
                    DurationCircleWidget(duration: duration),
                    SizedBox(width: 75), // Add space between texts
                    Text(
                      "Programs : $programNames",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 24, 81, 128),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress : ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 81, 128),
                      ),
                    ),
                    SizedBox(
                        height: 5), // Add space between title and progress bar
                    LinearProgressIndicator(
                      value: double.parse(currentTask["taskProgress"]) / 100,
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 24, 81, 128)),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _startTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task Started'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                            255, 24, 81, 128), // Set button color to blue
                      ),
                      child: Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        currentTask["taskDuration"] =
                            remainingDuration.toString();
                        _timer.cancel();
                        _dialogTimer.cancel();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task Stopped'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 24, 81, 128),
                      ),
                      child: Text(
                        'Pause',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Cancel Task"),
                              content:
                                  Text("Do you want to cancel  this Task?"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text("No"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    currentTask = {};
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Yes"),
                                ),
                              ],
                            );
                          },
                        ).then((value) {
                          if (value == true) {
                          } else {}
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Set button color to blue
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white), // Set text color to white
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10), // Add space between Block One and Two
        Expanded(
          child: Container(
            margin:
                EdgeInsets.symmetric(horizontal: 10), // Add margin for spacing
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 24, 81, 128).withOpacity(1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showProgressChartDialog(weekplan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 24, 81, 128),
                    elevation: 5,
                  ),
                  child: Text(
                    'Total Week \n Performance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    showTotalPerformanceProgressChartDialog(
                        calculateAverageTotalDayProgress(plans));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                        255, 24, 81, 128), // Set button color to white
                    elevation: 5, // Add shadow to the button
                  ),
                  child: Text(
                    'Total Performance',
                    style: TextStyle(
                        color: Colors.white), // Set text color to blue
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10), // Add space between Block Two and Three
      ],
    );
  }
}

class DurationCircleWidget extends StatelessWidget {
  final String duration;
  const DurationCircleWidget({Key? key, required this.duration})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // Set white background color
        border: Border.all(
            color: Color.fromARGB(255, 24, 81, 128),
            width: 2), // Add blue border
      ),
      alignment: Alignment.center,
      child: Text(
        duration,
        style: TextStyle(
          color: Color.fromARGB(255, 24, 81,
              128), // Change text color to black for better visibility
          fontSize: 12,
        ),
      ),
    );
  }
}

class SubmitTask extends StatefulWidget {
  @override
  _SubmitTaskState createState() => _SubmitTaskState();
}

class _SubmitTaskState extends State<SubmitTask> {
  bool isHovered = false;
  double sliderValue = 50;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDialog,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHovered ? Colors.green : Colors.white,
          border: Border.all(
            color: isHovered ? Colors.green : Color.fromARGB(255, 24, 81, 128),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check,
          color: isHovered ? Colors.white : Color.fromARGB(255, 24, 81, 128),
        ),
      ),
    );
  }

  String removeControlCharacters() {
    RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
    return responseBody.replaceAll(controlCharactersRegex, '');
  }

  String getName() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['patientName'];
    } catch (e) {
      // Handle parsing errors
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController textEditingController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text(
                          '${sliderValue.toInt()}%',
                          style: TextStyle(
                            color: Color.fromARGB(255, 24, 81, 128),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: sliderValue,
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              sliderValue = value;
                            });
                          },
                          activeColor: Color.fromARGB(255, 24, 81, 128),
                          inactiveColor: Colors.white,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color.fromARGB(255, 24, 81, 128)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: 'Write Review',
                      border: InputBorder.none,
                    ),
                    maxLines: 6,
                    minLines: 1,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                double dayProgress = 0.0;
                Map<String, dynamic> response =
                    jsonDecode(removeControlCharacters());
                String reviewText = textEditingController.text;
                String slider2 = sliderValue.toStringAsFixed(0);
                currentTask['Review'] = reviewText;
                currentTask['taskProgress'] = slider2;
                currentTask['submittedPercentage'] = slider2;
                if (sliderValue > 60) {
                  currentTask['submitted'] = 'true';
                }
                String name = getName();
                String currentDayName =
                    DateFormat('EEEE').format(DateTime.now());
                List<dynamic> weekPlans = response['plans'];
                for (var weekPlan in weekPlans) {
                  if (weekPlan['weekPlanName'] == WeekPlanName) {
                    List<dynamic> days = weekPlan['weekPlan'];
                    for (var day in days) {
                      if (day['dayName'] == currentDayName) {
                        List<dynamic> tasks = day['tasks'];
                        for (int i = 0; i < tasks.length; i++) {
                          if (tasks[i]['taskName'] == currentTask['taskName']) {
                            tasks[i] = currentTask;
                          }
                          dayProgress += double.parse(
                              tasks[i]['submittedPercentage'].toString());
                        }
                        dayProgress = dayProgress / tasks.length;

                        day['dayProgress'] = dayProgress.toStringAsFixed(0);
                        break;
                      }
                    }
                  }
                }
                String encodedResponse = json.encode(response);
                String url =
                    'https://server---app-d244e2f2d7c9.herokuapp.com/setPatientFile/'; // Update the URL

                try {
                  Map<String, dynamic> requestBody = {
                    'file':
                        encodedResponse, // Assuming file is the file you want to set
                    'patientName':
                        name, // Assuming patientName is the patient's name
                  };

                  http.Response response = await http.post(
                    Uri.parse(url),
                    body: jsonEncode(requestBody),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    print('File set successfully');
                  } else {
                    print('Error: ${response.statusCode}');
                  }
                } catch (error) {
                  print('Error: $error');
                }
                Navigator.of(context).pop();
                currentTask = {};
                responseBody = encodedResponse;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 24, 81, 128),
              ),
              child: Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'No',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Page4 extends StatefulWidget {
  Page4();
  @override
  _Page4State createState() => _Page4State();
}

class _Page4State extends State<Page4> {
  // Text editing controllers
  TextEditingController textController1 = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  TextEditingController textController3 = TextEditingController();
  TextEditingController textController4 = TextEditingController();
  bool isSecondPasswordFieldVisible = false;

  // Edit mode flag
  bool isEditMode = false;
  bool isEditEmail = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Settings'),
        leading: null,
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
                isSecondPasswordFieldVisible = !isSecondPasswordFieldVisible;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.email),
            onPressed: () {
              setState(() {
                isEditEmail = !isEditEmail;
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              TextFormField(
                controller: textController1,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: false,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: textController2,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: isEditMode,
                obscureText: true,
              ),
              SizedBox(height: 20),
              if (isSecondPasswordFieldVisible)
                TextFormField(
                  controller: textController3,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled: isEditMode,
                  obscureText: true,
                ),
              SizedBox(height: 20),
              TextFormField(
                controller: textController4,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 24, 81, 128)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: isEditEmail,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isEditMode ? _handleSubmit : null,
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color.fromARGB(255, 24, 81, 128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    print('Submit button pressed!');
    print('Field 2: ${textController2.text}');
    print('Field 3: ${textController3.text}');
  }
}
