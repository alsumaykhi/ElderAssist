import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/care_chat_provider.dart';

class MyCaregiverScreen extends StatefulWidget {
  const MyCaregiverScreen({super.key});

  static const String routePath = '/my-caregiver';
  static const String routeName = 'my_caregiver';

  @override
  State<MyCaregiverScreen> createState() => _MyCaregiverScreenState();
}

class _MyCaregiverScreenState extends State<MyCaregiverScreen> {
  bool _loading = true;
  String? _error;
  String? _caregiverUid;
  String? _caregiverName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCaregiver());
  }

  Future<void> _loadCaregiver() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = context.read<CareChatProvider>();
      final seniorId = provider.currentUid;
      if (seniorId == null) {
        throw Exception('Please sign in to continue.');
      }
      final caregiverUid = await provider.repository.caregiverIdForSenior(seniorId);
      if (caregiverUid == null || caregiverUid.isEmpty) {
        setState(() {
          _loading = false;
          _caregiverUid = null;
        });
        return;
      }
      final caregiverProfile = await provider.repository.getUserProfile(caregiverUid);
      final first = caregiverProfile?['firstName'] as String? ?? '';
      final last = caregiverProfile?['lastName'] as String? ?? '';
      setState(() {
        _caregiverUid = caregiverUid;
        _caregiverName = '$first $last'.trim();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My caregiver')),
      body: SafeArea(
        child: _loading
            ? const LoadingState(message: 'Loading caregiver…')
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(AppTheme.space6),
                    child: ErrorBanner(message: _error!),
                  )
                : _caregiverUid == null
                    ? const EmptyState(
                        icon: Icons.link_off_outlined,
                        title: 'No caregiver linked',
                        message:
                            'Link to a caregiver from Home to start secure chat and coordination.',
                      )
                    : Padding(
                        padding: const EdgeInsets.all(AppTheme.space6),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _caregiverName?.isNotEmpty == true
                                    ? _caregiverName!
                                    : 'Caregiver',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppTheme.space3),
                              const Text(
                                'Use secure chat to discuss updates and approve care coordination proposals.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: AppTheme.space5),
                              PrimaryButton(
                                label: 'Open chat',
                                icon: Icons.chat_bubble_outline,
                                onPressed: () {
                                  context.push('/care-chat/${_caregiverUid!}');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
