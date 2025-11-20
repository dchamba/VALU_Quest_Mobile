// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/services.dart'; // CORRETTO (era package.flutter)
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spider_chart/spider_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:valu_quest/APIs/configs.dart';
import 'package:valu_quest/Utils/app_colors.dart';
import 'package:valu_quest/Utils/log_utils.dart';
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
  bool dataStored = false;

  // Dati ricevuti dal server
  Map<String, dynamic>? apiResultData;

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
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.lightBlue,
    Colors.greenAccent,
  ];
  List<Color> blockColors = [];


  @override
  void initState() {
    super.initState();
    // Chiama la nuova funzione singola al caricamento
    processAndStoreQuestionnaire();
  }

  void setLoading(bool status) {
    if (mounted) {
      setState(() {
        isLoading = status;
      });
    }
  }

  /// Funzione singola che invia i dati grezzi,
  /// attende i calcoli dal server e riceve i risultati pronti per la UI.
  Future<void> processAndStoreQuestionnaire() async {
    setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("${URLs.baseURL}${URLs.processQuestionnaireURL}"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Dati utente
          "name": widget.name,
          "surname": widget.surname,
          "gender": widget.gender == "Male" ? "1" : "2",
          "dob": widget.dob,
          "email": widget.email,
          "bmiValue": widget.bmi,
          "height": widget.height,
          "weight": widget.weight,
          // Dati grezzi del questionario
          "selectedAnswers": widget.selectedAnswers,
        }),
      );

      LogUtils.log(
          "API : ${URLs.baseURL}${URLs.processQuestionnaireURL} ", response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true) {
          LogUtils.log("processAndStoreQuestionnaire()", "Dati processati e salvati con successo!");

          // Prepara i colori per il radar chart in base al numero di blocchi ricevuti
          final List averages = body['data']['blockAverages'] ?? [];
          final int numBlocks = averages.length;

          blockColors.clear();
          for (var i = 0; i < numBlocks; i++) {
            if (i < colors.length) {
              blockColors.add(colors[i]);
            } else {
              blockColors.add(colors[i % colors.length]); // Ricicla colori se finiscono
            }
          }

          if (mounted) {
            setState(() {
              apiResultData = body['data']; // Salva i dati per la build()
              dataStored = true;
            });
          }

        } else {
          // Errore logico dal server (es. dati mancanti)
          LogUtils.log("processAndStoreQuestionnaire() Errore Server", body['message'] ?? "Errore sconosciuto");
          if (mounted) {
            Navigator.pop(context);
            SnacbarUtils.show(context, "Errore dal server: ${body['message']}", true);
          }
        }
      } else {
        // Errore HTTP (404, 500, ecc)
        if (mounted) {
          Navigator.pop(context);
          SnacbarUtils.show(context, "Errore di connessione: ${response.statusCode} ", true);
        }
        LogUtils.log("processAndStoreQuestionnaire(): ${response.statusCode}", response);
      }
    } catch (e) {
      // Eccezione (es. parsing JSON fallito, niente internet)
      if(mounted){
        Navigator.pop(context);
        SnacbarUtils.show(context, e.toString(), true);
      }
      LogUtils.log("processAndStoreQuestionnaire() Eccezione", e);
    }

    setLoading(false);
  }

  @override
  Widget build(BuildContext context) {

    // Variabili locali estratte dai dati API (solo quando non è in loading e abbiamo dati)
    List<double> blockAverages = [];
    List<String> sortedUniqueBlockNewNames = [];
    List<dynamic> columnDataFreeText = [];
    List<dynamic> allCorrectionsToShowInFinalReport = [];
    double allBlockAverageUpdated = 0.0;
    List<ChartData> chartData = [];
    int firstBlockId = 0;
    int lastBlockId = 0;

    if (!isLoading && apiResultData != null) {
      try {
        // Parsing sicuro dei dati JSON
        blockAverages = (apiResultData!['blockAverages'] as List).map((e) => (e as num).toDouble()).toList();
        sortedUniqueBlockNewNames = (apiResultData!['sortedUniqueBlockNewNames'] as List).map((e) => e.toString()).toList();
        columnDataFreeText = apiResultData!['columnDataFreeText'] as List;
        allCorrectionsToShowInFinalReport = apiResultData!['allCorrectionsToShowInFinalReport'] as List;
        allBlockAverageUpdated = (apiResultData!['allBlockAverageUpdated'] as num).toDouble();

        // Conversione Mappa -> Lista per Grafico a Linee
        final Map<String, dynamic> blockAvgMap = Map<String, dynamic>.from(apiResultData!['sortedBlockAverageWithIDMap']);
        chartData = blockAvgMap.entries.map((e) => ChartData(int.parse(e.key), (e.value as num).toDouble())).toList();

        if (chartData.isNotEmpty) {
          chartData.sort((a, b) => a.x.compareTo(b.x)); // Assicura l'ordine per asse X
          firstBlockId = chartData.first.x;
          lastBlockId = chartData.last.x;
        }
      } catch (e) {
        LogUtils.log("Errore parsing dati build()", e);
      }
    }


    return WillPopScope(
      onWillPop: () {
        // Se i dati sono salvati, il tasto indietro porta alla registrazione
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
          title: const Text("Risultati"),
          backgroundColor: AppColor.backgroundColor,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        body: !isLoading && apiResultData != null
            ? SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [

              // --- 1. SPIDER CHART (RADAR) ---
              if (blockAverages.isNotEmpty && (!Configs.hideRadarChart))
                Container(
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
                      colors: blockColors,
                    ),
                  ),
                )
              else if (blockAverages.isEmpty && !Configs.hideRadarChart)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Dati insufficienti per generare il grafico."),
                ),

              const SizedBox(height: 20),

              // --- 2. LINE CHART (TABLE VISUALIZATION) ---
              if (!Configs.hideBlockAvgTable && chartData.isNotEmpty)
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
                        labelRotation: 90,
                        labelIntersectAction: AxisLabelIntersectAction.none,
                        interval: 1,
                        labelAlignment: LabelAlignment.end,
                        majorTickLines: const MajorTickLines(width: 0),
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: const TextStyle(fontSize: 10),
                        associatedAxisName: "Blocco",

                        axisLabelFormatter: (axisLabelRenderArgs) => ChartAxisLabel(
                            "${axisLabelRenderArgs.axis.associatedAxisName} ${axisLabelRenderArgs.text}",
                            const TextStyle() // Usa lo stile definito sopra
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                          enable: true,
                          format: 'Blocco point.x : point.y ',
                          header: "Risultati"),
                      backgroundColor: Colors.white30,
                      series: <CartesianSeries>[
                        // Linea Blu (Valori Blocchi)
                        LineSeries<ChartData, int>(
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                          color: Colors.blue,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                          ),
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                        ),
                        // Linea Rossa (Media Globale)
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
                                  firstBlockId,
                                  double.parse(allBlockAverageUpdated
                                      .toStringAsFixed(2))),
                              ChartData(
                                  lastBlockId,
                                  double.parse(allBlockAverageUpdated
                                      .toStringAsFixed(2)))
                            ],
                            xValueMapper: (ChartData data, _) => data.x,
                            yValueMapper: (ChartData data, _) => data.y)
                      ]),
                ),

              // --- 3. TABELLA TESTO LIBERO ---
              if (columnDataFreeText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      right: 10, left: 10, bottom: 20, top: 20),
                  child: TableWidget(
                      headerText: const ["Domanda", "Risultati"],
                      columnData: columnDataFreeText),
                ),

              const SizedBox(height: 20),

              // --- 4. MESSAGGI CORREZIONI ---
              if (!Configs.hideCorrectionsMessages)
                ...allCorrectionsToShowInFinalReport.map((correction) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColor.buttonColor),
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        tileColor: Colors.white30,
                        title: Text(
                          correction['correctionName'],
                          style: const TextStyle(
                              color: AppColor.buttonColor,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          correction['message'],
                        ),
                      ),
                    ),
                  );
                }).toList(),

              // --- 5. ETICHETTA MEDIA GLOBALE ---
              if (!Configs.hideGlobalAvgLabel)
                Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                    ),
                    margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                        child: Text(
                          "Media Globale ${allBlockAverageUpdated.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ))),

              const SizedBox(height: 20),

              // --- 6. SEZIONE THANK YOU ---
              if (!Configs.hideThankYouSection)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.check,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 70),
                      const Text(
                        "Grazie per la tua partecipazione!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Il sondaggio è stato compilato correttamente. I risultati verranno analizzati dall’amministratore.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                          backgroundColor: AppColor.buttonColor,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          SystemNavigator.pop(); // Chiude l'app
                        },
                        child: const Text("Chiudi"),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 50),
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