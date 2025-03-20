class URLs {
  //static const baseURL = "http://192.168.100.184/valu_api/";
  static const baseURL = "http://test.tcp.org.pk/valuapi/";

  static String getQuestionsURL = "get-question1.php";
  static String getChildQuestionsURL = "get-child-questions.php";
  static String getCorrectionsURL = "get-corrections.php";

  static String storeQuestionsURL = "store-questionnaire.php";

  static String surveyDatabaseConnection = "valu";

  static void saveSurveyDatabaseConnectionn(String surveyDatabaseConnection) {
    surveyDatabaseConnection = surveyDatabaseConnection;

    getQuestionsURL =
        "get-question1.php?connessioneDB=$surveyDatabaseConnection";
    getChildQuestionsURL =
        "get-child-questions.php?connessioneDB=$surveyDatabaseConnection";
    getCorrectionsURL =
        "get-corrections.php?connessioneDB=$surveyDatabaseConnection";
    storeQuestionsURL =
        "store-questionnaire.php?connessioneDB=$surveyDatabaseConnection";
  }
}
