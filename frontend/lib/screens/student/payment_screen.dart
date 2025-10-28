import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/providers/student_provider.dart';
import 'package:sportsverse_app/models/student_models.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadPayments();
      Provider.of<StudentProvider>(context, listen: false).loadPaymentSummary();
    });
  }

  Future<void> _processPayment(int enrollmentId, double amount) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Process payment through provider
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final success = await studentProvider.processPayment(
        enrollmentId: enrollmentId,
        amount: amount,
        paymentMethod: 'online',
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Text('Payment of \$${amount.toStringAsFixed(2)} has been processed successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Failed'),
            content: Text('Payment processing failed: ${studentProvider.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Failed'),
          content: Text('Payment processing failed: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment & Billing'),
            backgroundColor: const Color(0xFF006C62),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: studentProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006C62), Color(0xFF004D47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment & Billing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Manage your payments and view billing history',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Summary
                  _buildPaymentSummary(),
                  
                  const SizedBox(height: 24),
                  
                  // Enrollments with Payment Status
                  const Text(
                    'Enrollment Payments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (studentProvider.currentEnrollments.isEmpty && studentProvider.previousEnrollments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Color(0xFF7F8C8D),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No enrollments found',
                              style: TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...[...studentProvider.currentEnrollments, ...studentProvider.previousEnrollments]
                        .map((enrollment) => _buildEnrollmentPaymentCard(enrollment)),
                  
                  const SizedBox(height: 24),
                  
                  // Payment History
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (studentProvider.payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Color(0xFF7F8C8D),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payment history found',
                              style: TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...studentProvider.payments.map((payment) => _buildPaymentHistoryCard(payment)),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildPaymentSummary() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final paymentSummary = studentProvider.paymentSummary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Paid',
                  '\$${(paymentSummary['totalPaid'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.check_circle,
                  const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '\$${(paymentSummary['totalPending'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.pending,
                  const Color(0xFFE67E22),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Paid Transactions',
                  '${paymentSummary['paidCount'] ?? 0}',
                  Icons.receipt,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Pending Payments',
                  '${paymentSummary['pendingCount'] ?? 0}',
                  Icons.schedule,
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentPaymentCard(StudentEnrollment enrollment) {
    final batchName = enrollment.batchName;
    final enrollmentType = enrollment.enrollmentType;
    final sessionsAttended = enrollment.sessionsAttended;
    final totalSessions = enrollment.totalSessions ?? 0;
    final status = enrollment.enrollmentStatus;
    final startDate = enrollment.startDate;
    final endDate = enrollment.endDate;
    
    // Calculate payment status and amount
    final isCurrent = status == 'Active' || status == 'Not Started';
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final hasPendingPayments = studentProvider.hasPendingPayments(enrollment.id);
    final totalAmount = studentProvider.calculateEnrollmentAmount(enrollment.id);
    final paidAmount = studentProvider.calculatePaidAmount(enrollment.id);
    final pendingAmount = studentProvider.calculatePendingAmount(enrollment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrent ? Icons.play_circle : Icons.history,
                color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
                size: 24,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$enrollmentType • $sessionsAttended/$totalSessions sessions',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    if (startDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(startDate)}${endDate != null ? ' - ${DateFormat('MMM dd, yyyy').format(endDate)}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPendingPayments ? const Color(0xFFE67E22) : const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasPendingPayments ? 'Pending' : 'Paid',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Paid Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    Text(
                      '\$${paidAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    Text(
                      '\$${pendingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: pendingAmount > 0 ? const Color(0xFFE67E22) : const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Pay Button (if there are pending payments)
          if (hasPendingPayments && pendingAmount > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _processPayment(enrollment.id, pendingAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C62),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(StudentPayment payment) {
    final amount = payment.amount;
    final isPaid = payment.isPaid;
    final dueDate = payment.dueDate;
    final paidDate = payment.paidDate;
    final enrollmentId = payment.enrollmentId;
    
    // Find enrollment details
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final allEnrollments = [...studentProvider.currentEnrollments, ...studentProvider.previousEnrollments];
    final enrollment = allEnrollments.firstWhere(
      (e) => e.id == enrollmentId,
      orElse: () => StudentEnrollment(
        id: 0,
        studentId: 0,
        batchId: 0,
        enrollmentType: '',
        sessionsAttended: 0,
        isActive: false,
        enrollmentStarted: false,
        dateEnrolled: DateTime.now(),
        enrollmentStatus: '',
        progressDisplay: '',
        studentName: 'Unknown Student',
        studentLastName: '',
        batchName: 'Unknown Batch',
        branchName: '',
        organizationName: '',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid ? const Color(0xFF27AE60).withOpacity(0.3) : const Color(0xFFE67E22).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
            size: 24,
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.batchName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: \$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                if (dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
                if (isPaid && paidDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Paid: ${DateFormat('MMM dd, yyyy').format(paidDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Pending',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
