import 'package:flutter/material.dart';

class WhoCanDonatePage extends StatelessWidget {
  final List<Map<String, String>> criteria = [
    {"Age": "Be between 18 and 65 years old"},
    {"Weight": "Weigh at least 45 kg"},
    {
      "Hemoglobin":
          "Have a hemoglobin level of at least 12.5 g/dL for women and 13.0 g/dL for men"
    },
    {
      "Health":
          "Be in good health and not have any severe infections or illnesses"
    },
    {"Pulse": "Between 50 and 100/minute with no irregularities"},
    {"Blood Pressure": "Systolic 100-180 mm Hg and Diastolic 50-100 mm Hg"},
    {"Temperature": "Normal (oral temperature not exceeding 37.5°C)"},
    {
      "Other conditions":
          "Not have diabetes, chest pain, heart disease, high blood pressure, cancer, blood clotting problems, or blood disease"
    },
    {
      "History":
          "Not have donated blood or been treated for malaria in the past three months, and not have had any immunizations in the past one month"
    },
    {"Pregnancy and breastfeeding": "Not be pregnant or breastfeeding"},
    {"Menstrual cycles": "Not donate during your menstrual cycles"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 61, 150, 103),
        title: Text(
          'Who Can Donate Blood?',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.red.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eligibility Criteria',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 234, 64, 81),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: criteria.length,
                  itemBuilder: (context, index) {
                    final key = criteria[index].keys.first;
                    final value = criteria[index][key]!;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 61, 150, 103),
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 7, 7, 7),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
