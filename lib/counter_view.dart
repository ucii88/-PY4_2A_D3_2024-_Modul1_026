import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logbook : SRP version")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan Step",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  controller.setStep(int.tryParse(value) ?? 1);
                });
              },
            ),

            const SizedBox(height: 20),

            const Text('Total Hitungan:'),
            Text(
              '${controller.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Riwayat Aktivitas",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: controller.history.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada aktivitas",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.history.length,
                      itemBuilder: (context, index) {
                        return Text("- ${controller.history[index]}");
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "decrement",
            onPressed: () {
              setState(() {
                controller.decrement();
              });
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),

          FloatingActionButton(
            heroTag: "reset",
            onPressed: () {
              setState(() {
                controller.reset();
              });
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 10),

          FloatingActionButton(
            heroTag: "increment",
            onPressed: () {
              setState(() {
                controller.increment();
              });
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
