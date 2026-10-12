import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_auditor/models/daily_sales_summary.dart';
import 'package:sales_auditor/models/sale_transaction.dart';
import 'package:sales_auditor/widgets/sales_volume_breakdown_widget.dart';

void main() {
  group('Sales Volume Analysis & Box Pattern Tests', () {
    test('Unit Test: DailySalesSummary volumeDistribution records correct quantities for various ticket purchases', () {
      final now = DateTime.now();
      final txs = <SaleTransaction>[];

      // 5 people took 1 ticket each
      for (int i = 0; i < 5; i++) {
        txs.add(SaleTransaction(
          id: 'tx_1_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 1,
          totalAmount: 50.0,
          unitPrice: 50.0,
          isSetOrBulk: false,
        ));
      }

      // 2 tickets went out 30 times
      for (int i = 0; i < 30; i++) {
        txs.add(SaleTransaction(
          id: 'tx_2_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 2,
          totalAmount: 100.0,
          unitPrice: 50.0,
          isSetOrBulk: false,
        ));
      }

      // 8 lots of the 12-ticket set went out
      for (int i = 0; i < 8; i++) {
        txs.add(SaleTransaction(
          id: 'tx_12_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 12,
          totalAmount: 570.0,
          unitPrice: 47.5,
          isSetOrBulk: true,
        ));
      }

      final summary = DailySalesSummary(
        shopId: 'kdlr',
        date: now,
        transactions: txs,
      );

      // Verify exact quantities recorded
      expect(summary.volumeCount(1), 5);
      expect(summary.volumeCount(2), 30);
      expect(summary.volumeCount(12), 8);
      expect(summary.volumeCount(3), 0);

      // Verify singles vs sets counts
      expect(summary.singleOrdersCount, 35); // 5 + 30
      expect(summary.setOrdersCount, 8); // 8
      expect(summary.totalTransactionsCount, 43); // 5 + 30 + 8
      expect(summary.totalTicketsSold, (5 * 1) + (30 * 2) + (8 * 12)); // 5 + 60 + 96 = 161
    });

    testWidgets('Widget Test: SalesVolumeBreakdownWidget displays Left (Singles) and Right (Sets) Box Pattern columns and fires callback on tap', (tester) async {
      final now = DateTime.now();
      final txs = <SaleTransaction>[
        // 1 ticket - 5 quantities
        for (int i = 0; i < 5; i++)
          SaleTransaction(
            id: 'tx_1_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 1,
            totalAmount: 50.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 2 tickets - 8 quantities
        for (int i = 0; i < 8; i++)
          SaleTransaction(
            id: 'tx_2_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 2,
            totalAmount: 100.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 3 tickets - 6 quantities
        for (int i = 0; i < 6; i++)
          SaleTransaction(
            id: 'tx_3_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 3,
            totalAmount: 150.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 12 tickets - 10 quantities
        for (int i = 0; i < 10; i++)
          SaleTransaction(
            id: 'tx_12_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 12,
            totalAmount: 570.0,
            unitPrice: 47.5,
            isSetOrBulk: true,
          ),
      ];

      final summary = DailySalesSummary(
        shopId: 'kdlr',
        date: now,
        transactions: txs,
      );

      int? tappedCount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SalesVolumeBreakdownWidget(
                summary: summary,
                onSelectTicketCount: (count) {
                  tappedCount = count;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('SALES VOLUME BREAKDOWN'), findsOneWidget);
      expect(find.text('29 ORDERS TODAY'), findsOneWidget);

      // Verify Left Column: Singles (1, 2, 3)
      expect(find.text('SINGLES (LEFT)'), findsOneWidget);
      expect(find.text('1 Ticket'), findsOneWidget);
      expect(find.text('2 Tickets'), findsOneWidget);
      expect(find.text('3 Tickets'), findsOneWidget);

      // Verify Right Column: Sets (6, 12, 24, 36)
      expect(find.text('SETS (RIGHT)'), findsOneWidget);
      expect(find.text('12 Tickets'), findsOneWidget);
      expect(find.text('1 Full Set'), findsOneWidget);

      // Verify figures (quantities)
      expect(find.text('5'), findsWidgets); // 1 tix = 5 qty
      expect(find.text('8'), findsWidgets); // 2 tix = 8 qty
      expect(find.text('6'), findsWidgets); // 3 tix = 6 qty
      expect(find.text('10'), findsWidgets); // 12 tix = 10 qty

      // Test tapping box '12' triggers onSelectTicketCount(12)
      final box12 = find.byKey(const Key('volume_box_12'));
      expect(box12, findsOneWidget);
      await tester.tap(box12);
      expect(tappedCount, 12);

      // Test tapping box '1' triggers onSelectTicketCount(1)
      final box1 = find.byKey(const Key('volume_box_1'));
      expect(box1, findsOneWidget);
      await tester.tap(box1);
      expect(tappedCount, 1);
    });
  });
}
