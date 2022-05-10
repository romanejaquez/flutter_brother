import 'package:flutter/material.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FlutterPrintApp()
    )
   );
}

class FlutterPrintApp extends StatefulWidget {
  
  @override
  FlutterPrintAppState createState() => FlutterPrintAppState();
}

class FlutterPrintAppState extends State<FlutterPrintApp> with TickerProviderStateMixin {
  
  late AnimationController controller;
  bool isComplete = false;
  
  @override
  void initState() {
    super.initState();
    
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2)
    )..forward();
    
    controller.addListener(() {
      if (controller.isCompleted) {
      
        setState(() {
          isComplete = true;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Stack(
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -0.2), end: const Offset(0.0, -0.89)
                ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 200),
                    child: const Icon(
                      Icons.description, size: 60, color: Utils.darkGreen)
                  )
                )
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Material(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(50),
                  color: isComplete ? Utils.checkGreen : Utils.blueColor,
                  child: InkWell(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(
                        isComplete ? Icons.done :
                        Icons.description, color: Colors.white, size: 30)
                    )
                  )
                ) 
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(top: 200),
                    child: Column(
                      children: const [
                        Icon(Icons.swipe_up, color: Colors.grey, size: 50),
                        SizedBox(height: 20),
                        Text('Swipe Up\nTo Print', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.grey))
                      ]
                    ),
                  ),
                )
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onVerticalDragStart: (details) {
                        setState(() { isComplete = false; });
                      },
                      onVerticalDragUpdate: (details) {
                        int sensitivity = 8;
                        if (details.delta.dy < -sensitivity) {
                          controller.reset();
                          controller.forward();
                        }
                      },
                      child: Container(
                        height: 200,
                        width: 100,
                        decoration: const BoxDecoration(
                          color: Utils.lightGreen,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50)
                          )
                        ),
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: Utils.darkGreen,
                            borderRadius: BorderRadius.circular(50)
                          ),
                          child: const Icon(Icons.print, color: Colors.white, size: 40)
                        )
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Utils.blueColor
                      ),
                      child: const Text('Hello from Flutter!', 
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(fontSize: 15, color: Colors.white))
                    )
                  ]
                )
              )
            ]
          ),
        )
      )
    );
  }
}

class Utils {
  
  static const Color blueColor = Color(0xFF5B8CCE);
  static const Color darkGreen = Color(0xFF01B5A7);
  static const Color lightGreen = Color(0xFF32D8C7);
  static const Color checkGreen = Color(0xFF29D300);
}
