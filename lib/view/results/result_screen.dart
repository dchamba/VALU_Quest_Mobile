// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spider_chart/spider_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:valu_quest/Utils/app_colors.dart';
import 'package:valu_quest/Utils/log_utils.dart';
import 'package:valu_quest/test.dart';
import 'package:valu_quest/view/bmi/bmi_calculator.dart';
import 'package:valu_quest/view/register/registration_screen.dart';
import 'package:valu_quest/view/results/widgets/table.dart';

import 'package:http/http.dart' as http;

import '../../APIs/urls.dart';
import '../../Utils/snackbar_utils.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> selectedAnswers;
  final String name;
  final String surname;
  final String gender;
  final String dob;
  final String email;
  final double bmi;
  final String height;
  final String weight;
  const ResultScreen(
      {super.key,
      required this.selectedAnswers,
      required this.name,
      required this.surname,
      required this.gender,
      required this.dob,
      required this.email,
      required this.bmi,
      required this.height,
      required this.weight});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool isLoading = true;

  List<Color> colors = [
    Colors.deepPurpleAccent,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.black,
  ];
  List<double> blockAverages = [];
  double allBlockAverage = 0.0;
  double allBlockAverageUpdated = 0.0;
  List<String> sortedUniqueBlockIds = [];
  List<String> sortedUniqueBlockNames = [];
  List<String> sortedUniqueBlockNewNames = [];
  List<Color> blockColors = [];
  List<Map<int, double>>? sortedBlockAverageWithID = [];
  Map<String, double> sortedBlockAverageWithIDMap = {};
  List columnDataBlockAverage = [];
  List columnDataFreeText = [];
  List<dynamic> corrections = [];
  List<dynamic> matchedCorrections = [];

  void setLoading(bool status) {
    setState(() {
      isLoading = status;
    });
  }

  Future<void> getCorrections() async {
    setLoading(true);
    corrections.clear();
    try {
      final response = await http.get(
        Uri.parse("${URLs.baseURL}${URLs.getCorrectionsURL}"),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        LogUtils.log("API : ${URLs.baseURL}${URLs.getCorrectionsURL}",
            jsonDecode(response.body)['data']);

        if (jsonDecode(response.body)['success'] == true) {
          List<dynamic> data = jsonDecode(response.body)['data'];
          corrections = data;
          if (kDebugMode) {
            print("Corrections : total : ${data.length} > $corrections");
          }
        }
      } else {
        setLoading(false);
        LogUtils.log("getCorrections(): ${response.statusCode}", response);
      }
    } catch (e) {
      setLoading(false);
      LogUtils.log("getCorrections()", e);
    }
    calculations(widget.selectedAnswers);
  }

  void calculations(Map<String, dynamic> answers) {
    if(isLoading == false){
      setLoading(true);
    }

    blockAverages.clear();
    sortedUniqueBlockIds.clear();
    blockColors.clear();
    allBlockAverage = 0.0;
    columnDataBlockAverage.clear();
    columnDataFreeText.clear();
    sortedUniqueBlockNames.clear();
    sortedUniqueBlockNewNames.clear();
    sortedBlockAverageWithID!.clear();
    sortedBlockAverageWithIDMap.clear();

    try {
      Set<int> uniqueBlockIds = {};
      Map<String, List<double>> blockValues = {};
      answers.forEach((key, value) {
        if (value['optionId'] != null) {
          int blockId = int.parse(value['blockNewName'].split(" ")[1]);
          String blockName = value['blockName'] ?? "";
          double optionValue = double.parse(value['option_value'].toString());
          uniqueBlockIds.add(blockId);
          if (!blockValues.containsKey(blockName)) {
            blockValues[blockName] = [optionValue];
          } else {
            blockValues[blockName]!.add(optionValue);
          }
        }
      });

      var sortedBlockValues = Map.fromEntries(blockValues.entries.toList()
        ..sort((a, b) {
          int keyA = int.parse(a.key.split("-")[0].split(" ")[1]);
          int keyB = int.parse(b.key.split("-")[0].split(" ")[1]);

          return keyA.compareTo(keyB);
        }));
      sortedBlockValues.entries.toList().map((e) {
        sortedUniqueBlockNewNames.add(e.key.split("-").first);
      }).toList();

      sortedBlockValues.forEach((blockId, values) {
        double sum = values.reduce((value, element) => value + element);
        double average = sum / values.length;
        average = double.parse(average.toStringAsFixed(1));
        blockAverages.add(average);
      });
      sortedUniqueBlockIds =
          uniqueBlockIds.toList().map((id) => id.toString()).toList();
      sortedUniqueBlockIds.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      sortedUniqueBlockNames.addAll(sortedBlockValues.keys);
      double allBlockSum = 0.0;
      for (var element in blockAverages) {
        allBlockSum += element;
      }
      allBlockAverage = double.parse(
          (allBlockSum / sortedUniqueBlockIds.length).toStringAsFixed(2));

      for (var i = 0; i < sortedUniqueBlockIds.length; i++) {
        blockColors.add(colors[i]);
        sortedBlockAverageWithIDMap[sortedUniqueBlockIds[i]] = blockAverages[i];
        sortedBlockAverageWithID!
            .add({int.parse(sortedUniqueBlockIds[i]): blockAverages[i]});

        columnDataBlockAverage.add({
          "id": sortedBlockValues.keys.elementAt(i),
          "average": blockAverages[i]
        });
      }

      // columnDataBlockAverage
      //     .add({"id": "Media Globale", "average": allBlockAverage});

      answers.forEach((key, value) {
        if (value['optionId'] == null) {
          columnDataFreeText.add(
              {"id": value['questionName'], "average": value["option_value"]});
        }
      });
      applyCorrections();

      if (kDebugMode) {
        print("Block IDs: $sortedUniqueBlockIds");
        print("Total Blocks: ${sortedUniqueBlockIds.length}");
        print("Total Blocks: ${sortedBlockValues}");
        print("Average Option Values for Each Block:");
        for (var entry in blockAverages) {
          if (kDebugMode) {
            print("Block $entry");
          }
        }
      }
    } catch (e) {
      setLoading(false);
      LogUtils.log("calculation()", e.toString());
    }
  }

  bool calculateAndValidate({
    required dynamic condition,
    required double value,
    bool? previousResult,
    bool betweenOperator = false,
  }) {
    bool result = false;

    double value1 = double.parse(condition['conditionValue1'].toString());


    String conjunction = condition['conjunction'];

      switch (condition["operator"]) {
        case "=":
          result = value == value1;
          break;
        case "!=":
          result = value != value1;
          break;
        case ">":
          result = value > value1;
          break;
        case "<":
          result = value < value1;
          break;
        case ">=":
          result = value >= value1;
          break;
        case "<=":
          result = value <= value1;
          break;
        case "between":
          double value2 = double.parse(condition['conditionValue2'].toString());
          result = value >= value1 && value <= value2;
          break;
        default:
          throw Exception("Unsupported operator: ${condition["operator"]}");
      }
    //print("$value $value1 ${condition["operator"]} $value2 $result");
    if (previousResult != null) {
      if (conjunction == "AND") {
        result = previousResult && result;
      } else if (conjunction == "OR") {
        result = previousResult || result;
      }else if (conjunction == "None") {
        result = previousResult;
      } else {
        throw Exception("Unsupported conjunction: $conjunction");
      }
    }
    return result;
  }

  Future<void> applyCorrections() async {
    allBlockAverageUpdated = 0.0;
    matchedCorrections.clear();
    try {
      for (var correction in corrections) {

        List<dynamic> conditions = correction['conditions'];


        bool? previousResult;
        bool skipRestConditions = false;

        for (var condition in conditions) {
          condition['isApplied'] = 0;
          String currentConjunction = condition['conjunction'];
          String? previousConjunction;
          if(condition['conditionType'] == "Block") {

            for (Map<int, double> block in sortedBlockAverageWithID!) {
              if(block.entries.first.key == int.parse(condition['blockId'].toString())){
                previousResult = calculateAndValidate(
                    previousResult: previousResult, condition: condition, value: block.entries.first.value);

                if (previousResult == true) {
                  condition['isApplied'] = 1;
                  break;
                }
                if (currentConjunction == "AND" && previousResult == false) {
                  skipRestConditions = true;
                  break;
                }
              }

            }

          }else if(condition['conditionType'] == "Global Value"){

            previousResult = calculateAndValidate(
                previousResult: previousResult, condition: condition, value: allBlockAverage);

            if (previousResult == true) {
              condition['isApplied'] = 1;
            }
            if (currentConjunction == "AND" && previousResult == false) {
              skipRestConditions = true;
              break;
            }


          }else if(condition['conditionType'] == "BMI Value"){

            previousResult = calculateAndValidate(
                previousResult: previousResult, condition: condition, value: widget.bmi);

            if (previousResult == true) {
              condition['isApplied'] = 1;
            }

            if (currentConjunction == "AND" && previousResult == false) {
              skipRestConditions = true;
              break;
            }

          }else{
            throw Exception("Unsupported conditionType: ${condition['conditionType']}");
          }

          if (skipRestConditions) {
            break;
          }

          if(previousConjunction != null){
            if(previousConjunction == "AND" && previousResult! == false){
              previousResult == false;
            }
          }
          previousConjunction = currentConjunction;

        }

        //==
        if (previousResult == true) {
          matchedCorrections.add(correction);
        }

      }
      matchedCorrections.map((correction) {
        allBlockAverageUpdated += double.parse(correction['valueToAdd'].toString());
      }).toList();
      allBlockAverageUpdated += allBlockAverage;
      storeQuestions();
    } catch (e) {
      setLoading(false);
      LogUtils.log("applyCorrections()", e.toString());
    }
  }

  bool dataStored = false;
  Future<void> storeQuestions() async {
    setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("${URLs.baseURL}${URLs.storeQuestionsURL}"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": widget.name,
          "surname": widget.surname,
          "gender": widget.gender == "Male" ? "1" : "2",
          "dob": widget.dob,
          "email": widget.email,
          "selectedAnswers": widget.selectedAnswers,
          "globalAvgVal_org": allBlockAverage,
          "bmiValue": widget.bmi,
          "height": widget.height,
          "weight": widget.weight,
          "blockAverageWithID": sortedBlockAverageWithIDMap,
          "globalValue_after" : allBlockAverageUpdated,
          "corrections" : matchedCorrections
        }),
      );
      LogUtils.log(
          "API : ${URLs.baseURL}${URLs.storeQuestionsURL} ", response.body);
      if (response.statusCode == 200 &&
          jsonDecode(response.body)['success'] == true) {
        LogUtils.log("API : ${URLs.baseURL}${URLs.storeQuestionsURL}",
            jsonDecode(response.body));
        SnacbarUtils.show(
            context, "Sondaggio completato con successo !", false);
        setState(() {
          dataStored = true;
        });
        LogUtils.log("storeQuestions(): ${response.statusCode}",
            "Data Inserted successfully!");
      } else {
        setLoading(false);
        Navigator.pop(context);
        SnacbarUtils.show(context,
            "Qualcosa è andato storto!, Errore: ${response.statusCode} ", true);
        LogUtils.log("storeQuestions(): ${response.statusCode}", response);
      }
    } catch (e) {
      setLoading(false);
      SnacbarUtils.show(context, e.toString(), true);
    }
    setLoading(false);
  }

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    getCorrections();

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (dataStored == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                (route) => false,
          );
        }
        return Future(() => dataStored == true ? false : true);

      },
      child: Scaffold(
        backgroundColor: AppColor.backgroundColor,
        appBar: AppBar(
          title: const Text("Resultati"),
          backgroundColor: AppColor.backgroundColor,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        body: !isLoading
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    //table block result
                   /* Padding(
                      padding: const EdgeInsets.only(
                        right: 10,
                        left: 10,
                        bottom: 20,
                      ),
                      child: TableWidget(
                          headerText: const ["Blocco", "Resultati"],
                          columnData: columnDataBlockAverage),
                    ),

                    */
                    //spider chart
                    /* blockAverages.length == sortedUniqueBlockIds.length
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 40, bottom: 40),
                            color: Colors.white30,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: MediaQuery.of(context).size.width * 0.6,
                              child: SpiderChart(
                                data: blockAverages,
                                labels: sortedUniqueBlockNewNames,
                                decimalPrecision: 1,
                                colorSwatch: Colors.cyan,
                                colors: blockColors,
                              ),
                            ),
                          )
                        : const Text("Something went wrong!"),
                    */
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 400,
                      child: SfCartesianChart(
                          margin: const EdgeInsets.only(
                              right: 15, left: 15, top: 15),
                          primaryYAxis: NumericAxis(
                            minimum: 0,
                            maximum: 6,
                            interval: 0.5,
                            majorGridLines: const MajorGridLines(width: 0),
                            plotBands: <PlotBand>[
                              PlotBand(
                                isVisible: true,
                                start: 2.5,
                                end: 5,
                                color: Colors.green.shade200,
                              ),
                            ],
                          ),
                          primaryXAxis: CategoryAxis(
                            labelRotation: 45,
                            labelAlignment: LabelAlignment.end,
                            majorTickLines: const MajorTickLines(width: 0),
                            majorGridLines: const MajorGridLines(width: 0),
                            labelStyle: const TextStyle(fontSize: 12),
                            associatedAxisName: "Blocco",
                            axisLabelFormatter: (axisLabelRenderArgs) =>
                                ChartAxisLabel(
                                    "${axisLabelRenderArgs.axis.associatedAxisName} ${axisLabelRenderArgs.text}",
                                    const TextStyle()),
                          ),
                          tooltipBehavior: TooltipBehavior(
                              enable: true,
                              format: 'Blocco point.x : point.y ',
                              header: "Resultati"),
                          backgroundColor: Colors.white30,
                          series: <CartesianSeries>[
                            // LineSeries<ChartData, int>(
                            //   dataLabelSettings: const DataLabelSettings(
                            //     isVisible: true,
                            //   ),
                            //   color: Colors.blue,
                            //   markerSettings: const MarkerSettings(
                            //     isVisible: true,
                            //   ),
                            //   initialSelectedDataIndexes: [2],
                            //   dataSource: sortedBlockAverageWithID!.map((e) {
                            //     return (ChartData(
                            //         e.keys.first, e.values.first));
                            //   }).toList(),
                            //   xValueMapper: (ChartData data, _) => data.x,
                            //   yValueMapper: (ChartData data, _) => data.y,
                            // ),
                            LineSeries<ChartData, int>(
                                color: Colors.red,
                                enableTooltip: false,
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    textStyle: TextStyle(color: Colors.red)),
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                ),
                                dataSource: [
                                  ChartData(
                                      int.parse(sortedUniqueBlockIds.first),
                                      double.parse(allBlockAverageUpdated.toStringAsFixed(2))),
                                  ChartData(
                                      int.parse(sortedUniqueBlockIds.last),
                                      double.parse(allBlockAverageUpdated.toStringAsFixed(2)))
                                ],
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y)
                          ]),
                    ),
                    // Container(
                    //     width: double.infinity,
                    //   padding: EdgeInsets.symmetric(vertical: 5),
                    //   margin: EdgeInsets.symmetric(horizontal: 20),
                    //     decoration: BoxDecoration(
                    //       color: Colors.blue,
                    //       borderRadius: BorderRadius.circular(5)
                    //     ),
                    //     child: Center(
                    //         child: Text(
                    //       "Media Globale iniziale: $allBlockAverage",
                    //       style: const TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 22,
                    //       ),
                    //     ))),
                    // blockAverages.length == sortedUniqueBlockIds.length
                    //     ? Container(
                    //         padding: const EdgeInsets.only(
                    //             right: 10, left: 20, bottom: 10),
                    //         color: Colors.white30,
                    //         child: SizedBox(
                    //           width: double.infinity,
                    //           height: MediaQuery.of(context).size.width * 0.5,
                    //           child: DChartLineN(
                    //             animationDuration: const Duration(seconds: 1),
                    //             animate: true,
                    //             allowSliding: true,
                    //             configRenderLine: ConfigRenderLine(
                    //                 includePoints: true, includeArea: true),
                    //             groupList: [
                    //               NumericGroup(
                    //                 id: '1',
                    //                 color: Colors.blue,
                    //                 data: blockAverages.map((e) {
                    //                   return NumericData(
                    //                       domain: int.parse(
                    //                           sortedUniqueBlockIds.elementAt(
                    //                               blockAverages.indexOf(e))),
                    //                       measure: e,
                    //                       color: Colors.red);
                    //                 }).toList(),
                    //               ),
                    //               NumericGroup(
                    //                 id: '2',
                    //                 color: Colors.red,
                    //                 chartType: ChartType.line,
                    //                 data: sortedUniqueBlockIds.map((e) {
                    //                   return NumericData(
                    //                       domain: double.parse(e),
                    //                       measure: allBlockAverage,
                    //                       color: Colors.red);
                    //                 }).toList(),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       )
                    //     : const Text("Something went wrong!"),
                    if (columnDataFreeText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 10, left: 10, bottom: 20, top: 20),
                        child: TableWidget(
                            headerText: const ["Domanda", "Resultati"],
                            columnData: columnDataFreeText),
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    ...matchedCorrections.map((correction) {

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: AppColor.buttonColor),borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                             tileColor: Colors.white30,
                            title: Text(correction['correctionName'],style: const TextStyle(color: AppColor.buttonColor,fontWeight: FontWeight.bold),),
                            subtitle: Text(correction['message'],),
                            //trailing: Text(correction["valueToAdd"],style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.red),),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 5,),
                        margin: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(5)
                        ),
                        child: Center(
                            child: Text(
                              "Media Globale ${allBlockAverageUpdated.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ))),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              )
            : Center(
                child: LoadingAnimationWidget.inkDrop(
                    color: AppColor.buttonColor, size: 50)),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}
