import 'dart:convert';
import 'dart:ffi';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // === Property ===

  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController glucoseController = TextEditingController();
  double glucose = 0.0;
  int age = 0;
  double skinTickness = 0.0;
  double bmi = 0.0;
  bool isParent = false;
  bool isSiblings = false;
  bool isGrandparents = false;
  Color backgroundColor = Color.fromARGB(251, 10, 4, 94);
  Color suyellow = Color(0xFFF8DE7D);
  String _resultMessage = "정보를 입력하고 예측 버튼을 눌러주세요.";
  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    glucoseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('당뇨 예측', style: _buildTextStyle(25)),
        backgroundColor: backgroundColor,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              reset();
            },
            icon: Icon(Icons.refresh, color: suyellow, size: 30),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildInputText(ageController, '나이(필수)'),
              _buildInputText(heightController, '키(필수)'),
              _buildInputText(weightController, '몸무게(필수)'),
              _buildInputText(glucoseController, '혈당(선택)', true),
              _buildPedigree(),
              Text(_resultMessage, style: _buildTextStyle(15)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    checkValue();
                  },
                  child: Text('예측 시도', style: TextStyle(fontSize: 25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // build

  // === Widget ===

  Widget _buildInputText(
    TextEditingController controller,
    String txt, [
    bool isOption = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(txt, style: _buildTextStyle(22))),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hint: isOption
                    ? Text('선택', style: _buildTextStyle(20))
                    : Text(''),
              ),
              style: _buildTextStyle(20),
            ),
          ),
        ],
      ),
    );
  } // _buildInputText

  TextStyle _buildTextStyle(double size) {
    return TextStyle(color: suyellow, fontSize: size);
  }

  Widget _buildPedigree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('가족 중에 당뇨 환자가 있으신가요?', style: _buildTextStyle(20)),
        returnCheckBox('부모님', isParent, (value) {
          setState(() {
            isParent = value!;
          });
        },),
        returnCheckBox('형제 자매', isSiblings,(value) {
          setState(() {
            isSiblings = value!;
          });
        },),
        returnCheckBox('조부모님', isGrandparents,(value) {
          setState(() {
            isGrandparents = value!;
          });
        },),
      ],
    );
  }

  Widget returnCheckBox(String txt, bool b, Function(bool?) onChanged) { // onChanged 추가
  return Row(
    children: [
      Checkbox(
        value: b,
        activeColor: suyellow, // 디자인 일관성을 위해 추가
        checkColor: backgroundColor,
        onChanged: onChanged, // 매개변수로 받은 함수 연결
      ),
      Text(txt, style: _buildTextStyle(22)),
    ],
  );
}

  // === Function ===

  void reset() {
    ageController.text = "";
    heightController.text = "";
    weightController.text = "";
    glucoseController.text = "";
    isParent = false;
    isSiblings = false;
    isGrandparents = false;
    _resultMessage = "정보를 입력하고 예측 버튼을 눌러주세요.";
    setState(() {
      
    });
  }

  void checkValue() {
    if (ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty) {
      errorSnackBar('경고', '빈 값이 있음');
    } else {
      _predictDiabetes();
    }
  }

  void errorSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  double calcBMI() {
    var h = double.parse(heightController.text)/100;
    var w = double.parse(weightController.text);
    return double.parse((w / (h * h)).toStringAsFixed(1));
  }

  double calcPedigreeScore()
  {
    double score = 0.078; // 최소값 기준
    if (isParent) score += 1.0;
    if (isSiblings) score += 0.8;
    if (isGrandparents) score += 0.5;
    var pedigreeScore = double.parse(math.log(1 + score).toStringAsFixed(4));
    print('pedigreeScore : $pedigreeScore / $score');
    return pedigreeScore; 
  }

  double calcGlucose()
  {
    var g = (0.9806825594100111 * bmi) + (0.6817116341473727 * age) + 65.60660909858092;
    print('Glucose : ${g}');
    return g;
  }

  double calcTickness()
  {
    var  slope = 0.95 ;
    var intercept = -2.5;
    var tickness = (slope * bmi) + intercept;
    print('tickness : ${tickness}');
    return(slope * bmi) + intercept;
  }

  Future<void> _predictDiabetes() async {
    const url = 'http://192.168.0.17:8000/predict'; // 실제 폰 테스트 시엔 로컬 IP 주소 사용
    
    bmi = calcBMI();
    print('bmi : $bmi');
    age = int.parse(ageController.text);
    if(glucoseController.text.isEmpty)
    {
      glucose = calcGlucose();
    }
    else
    {
      glucose = double.parse(glucoseController.text);
    }
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'glucose': glucose,
          'bmi': bmi,
          'age': age,
          'pedigree_log': calcPedigreeScore(),
          'skin' : calcTickness()
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultMessage = "결과: ${data['result']}\n확률: ${data['probability']}%";
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = "에러가 발생했습니다: $e";
        print(_resultMessage);
      });
    }
  }
}
