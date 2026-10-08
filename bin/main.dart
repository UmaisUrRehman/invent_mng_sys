import 'package:inventory_management_system/services/file_service.dart';
import 'package:inventory_management_system/services/inventory.dart';
import 'package:inventory_management_system/services/stock_monitor.dart';
import 'package:inventory_management_system/utils/cli.dart';

Future<void> main() async {
  //instantiating services
  final inventory = Inventory();
  final fileService = FileService();
  final stockMonitor = StockMonitor();

  //instantiating cli
  final cli = CLI(
    inventory: inventory,
    fileService: fileService,
    stockMonitor: stockMonitor,
  );

  await cli.start();
}