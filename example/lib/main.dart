import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:another_brother/custom_paper.dart';
import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart' as pi;
import 'package:another_brother/type_b_commands.dart';
import 'package:another_brother/type_b_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "dart:ui" as ui;
import 'dart:async';

import 'package:flutter/services.dart';

//import 'package:flutter_scan_bluetooth/flutter_scan_bluetooth.dart';
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under another_brother.
void main() {
  //runApp(MyApp());
  //runApp(TbPrinterSetup());

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
  
  AnimationController controller;
  AnimationController slideController;
  bool isComplete = false;
  bool showSwipeIndicator = true;
  bool showGlowingSwipe = false;
  Timer timer;
  
  @override
  void initState() {
    super.initState();
    
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500)
    );

    slideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2)
    )..repeat();
    
    controller.addListener(() {
      if (controller.isCompleted) {

        timer = Timer(const Duration(seconds: 2), () {
          timer.cancel();

          setState(() {
            isComplete = false;
            showSwipeIndicator = true;
            
          });
        });
      
        setState(() {
          isComplete = true;
          showGlowingSwipe = false;
          
          slideController.reset();
          slideController.repeat();

          printImageBluetooth();
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<pi.PrinterStatus> printImageBluetooth() async {

    var printer = new pi.Printer();
    var printInfo = pi.PrinterInfo();
    printInfo.printerModel = pi.Model.PT_P910BT;
    printInfo.printMode = pi.PrintMode.FIT_TO_PAGE;
    printInfo.isAutoCut = true;
    printInfo.port = pi.Port.BLUETOOTH;
    printInfo.numberOfCopies = 1;
    printInfo.labelNameIndex = PT.ordinalFromID(PT.W36.getId());   
    
    List<pi.BluetoothPrinter> netPrinters =
        await printer.getBluetoothPrinters([pi.Model.PT_P910BT.getName()]);
    print("Bt Printers Found: $netPrinters");
    printInfo.macAddress = netPrinters.single.macAddress;

    await printer.setPrinterInfo(printInfo);

    TextStyle style = TextStyle(
        color: Colors.black,
        fontSize: 30,
        fontWeight: FontWeight.bold
    );

    ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize:   style.fontSize,
          fontFamily: style.fontFamily,
          fontStyle:  style.fontStyle,
          fontWeight: style.fontWeight,
          textAlign: TextAlign.center,
          maxLines: 10,
        )
    )
      ..pushStyle(style.getTextStyle())
      ..addText("Hello from Flutter!");

    ui.Paragraph paragraph = paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: 300));

    pi.PrinterStatus status = await printer.printText(paragraph);

    print("Got Status: $status and Error: ${status.errorCode.getName()}");
    return status;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Stack(
            children: [
              PrintPaperAnimation(
                controller: controller
              ),
              Align(
                 alignment: Alignment.topCenter,
                 child: Visibility(
                   visible: isComplete,
                   child: Container(
                     margin: const EdgeInsets.only(top: 20),
                     child: GlowingButton(
                       repeat: false,
                       radius: 80,
                       color: Utils.checkGreen,
                     ),
                   ),
                 ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                          Icons.print, color: Colors.white, size: 30)
                      )
                    )
                  ),
                ) 
              ),
              PrintStatusMessage(
                isComplete: isComplete,
                showSwipeIndicator: showSwipeIndicator
              ),
              Center(
                child: Visibility(
                  visible: showSwipeIndicator,
                  child: SwipeUpIndicator(
                    swipeController: slideController,
                  ),
                )
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Visibility(
                  visible: showGlowingSwipe,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 125),
                    child: GlowingButton(repeat: false, radius: 100, color: Utils.lightGreen)
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
                        if (timer != null) {
                          timer.cancel();
                        }

                        setState(() { 
                          showGlowingSwipe = true;
                          isComplete = false;
                          showSwipeIndicator = false;
                        });
                      },
                      onVerticalDragUpdate: (details) {
                        int sensitivity = 8;
                        if (details.delta.dy < -sensitivity) {
                          controller.reset();
                          controller.forward();
                        }
                      },
                      // onVerticalDragEnd: (details) {
                      //   printImageBluetooth();
                      // },
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
                          child: const Icon(Icons.description, color: Colors.white, size: 40)
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

class GlowingButton extends StatefulWidget {
  
  final Color color;
  final double radius;
  final bool repeat;

  const GlowingButton({ this.color, this.radius, this.repeat });

  @override
  GlowingButtonState createState() => GlowingButtonState();
}

class GlowingButtonState extends State<GlowingButton> with TickerProviderStateMixin {
  
  AnimationController glowingController;
  
  @override
  void initState() {
    super.initState();
    
    glowingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.repeat) {
      glowingController.repeat();
    }
    else {
      glowingController.forward();
    }
  }
  
  @override
  void dispose() {
    glowingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 2)
            .animate(CurvedAnimation(parent: glowingController, curve: Curves.easeInOut)),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0)
              .animate(CurvedAnimation(parent: glowingController, curve: Curves.easeInOut)),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                width: widget.radius,
                height: widget.radius,
              ),
            )
          ),
        ]
      )
    );
  }
}

class SwipeUpIndicator extends StatefulWidget {

  final AnimationController swipeController;

  const SwipeUpIndicator({Key key, this.swipeController}) : super(key: key);

  @override
  State<SwipeUpIndicator> createState() => _SwipeUpIndicatorState();
}

class _SwipeUpIndicatorState extends State<SwipeUpIndicator> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        margin: const EdgeInsets.only(top: 200),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 2.0),
                        end: const Offset(0.0, 0.0)
                      ).animate(CurvedAnimation(parent: widget.swipeController, curve: Curves.easeInOut)
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0)
                      .animate(CurvedAnimation(
                        parent: widget.swipeController, 
                        curve: Curves.easeInOut)
                      ),
                      child: Icon(Icons.swipe_up, color: Colors.grey, size: 70),
                    ),
                  )
                ],
              )
            ),
            Text('Swipe Up\nTo Print', textAlign: TextAlign.center, style: TextStyle(
              fontSize: 25, color: Colors.grey))
          ]
        ),
      ),
    );
  }
}

class PrintPaperAnimation extends StatefulWidget {

  final AnimationController controller;

  PrintPaperAnimation({Key key, this.controller }) : super(key: key);

  @override
  State<PrintPaperAnimation> createState() => _PrintPaperAnimationState();
}

class _PrintPaperAnimationState extends State<PrintPaperAnimation>  with SingleTickerProviderStateMixin {
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, -0.2), end: const Offset(0.0, -0.87)
      ).animate(CurvedAnimation(parent: widget.controller, curve: Curves.easeOut)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 200),
          child: const Icon(
            Icons.description, size: 60, color: Utils.darkGreen)
        )
      )
    );
  }
}

class PrintStatusMessage extends StatefulWidget {

  final bool isComplete;
  final bool showSwipeIndicator;

  PrintStatusMessage({Key key, this.isComplete, this.showSwipeIndicator }) : super(key: key);

  @override
  State<PrintStatusMessage> createState() => _PrintStatusMessageState();
}

class _PrintStatusMessageState extends State<PrintStatusMessage> {
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Visibility(
        visible: !widget.showSwipeIndicator,
        child: Container(
          margin: const EdgeInsets.only(top: 150),
          child: Text(
            !widget.isComplete ? 'Preparing File\nFor Printing' : 'Success!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              color: !widget.isComplete ? Utils.blueColor : Utils.checkGreen
            )  
          ),
        )
      )
    );
  }
}