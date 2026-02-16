import 'package:flutter/material.dart';
import 'counter_controller.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, this.username = "User"});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController controller = CounterController();
  final TextEditingController stepController = TextEditingController();

  @override
  void dispose() {
    stepController.dispose();
    super.dispose();
  }

  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 17) return "Selamat Siang";
    return "Selamat Malam";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 176, 164, 246),
          centerTitle: true,
          title: Text(
            "Logbook : (${widget.username})",
            style: TextStyle(
              color: Color.fromARGB(255, 79, 30, 152),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Konfirmasi Logout"),
                      content: const Text(
                        "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingView(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text(
                            "Ya, Keluar",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                "${greeting()}, ${widget.username}!",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: stepController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: "Masukkan Step",
                          border: OutlineInputBorder(),
                        ),

                        onChanged: (value) {
                          controller.setStep(int.tryParse(value) ?? 1);
                        },

                        onSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Total Hitungan",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '${controller.value}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const Text(
                "Riwayat Aktivitas",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Flexible(
                child: controller.history.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          "Belum ada aktivitas",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.history.length,
                        itemBuilder: (context, index) {
                          final historyText = controller.history[index];

                          Color textColor = Colors.black;
                          if (historyText.contains("bertambah")) {
                            textColor = Colors.green;
                          } else if (historyText.contains("berkurang")) {
                            textColor = Colors.red;
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "- $historyText",
                              style: TextStyle(color: textColor),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        floatingActionButton: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "decrement",
                backgroundColor: Colors.red,
                onPressed: () {
                  setState(() {
                    controller.decrement();
                  });
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 12),

              FloatingActionButton(
                heroTag: "reset",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Konfirmasi"),
                        content: Text("Yakin ingin reset?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                controller.reset();
                              });
                              Navigator.pop(context);
                            },
                            child: Text("Reset"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 10),

              FloatingActionButton(
                heroTag: "increment",
                backgroundColor: Colors.green,
                onPressed: () {
                  setState(() {
                    controller.increment();
                  });
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
