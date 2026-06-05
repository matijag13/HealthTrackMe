import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/detective_insight.dart';
import '../services/api_service.dart';
import '../services/detective_service.dart';
import '../widgets/detective_insight_detail.dart';

class DetectiveScreen extends StatefulWidget {
  const DetectiveScreen({super.key});

  @override
  State<DetectiveScreen> createState() => _DetectiveScreenState();
}

class _DetectiveScreenState extends State<DetectiveScreen>
    with SingleTickerProviderStateMixin {
  final DetectiveService _detectiveService = DetectiveService();
  final ApiService _api = ApiService.instance;

  DetectiveInsight? _currentInsight;
  List<DetectiveInsight> _insightHistory = [];
  bool _loading = true;
  bool _regenerating = false;
  String? _error;
  String _selectedTimeRange = 'WEEK';
  late TabController _tabController;

  final TextEditingController _questionController = TextEditingController();
  bool _asking = false;
  String? _answer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInsight();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _asking) return;

    FocusScope.of(context).unfocus();
    setState(() => _asking = true);
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        if (mounted) {
          DetectiveService.showError(context, 'No active user selected');
        }
        return;
      }
      final answer = await _detectiveService.askQuestion(
        userId: userId,
        question: question,
      );
      if (mounted) setState(() => _answer = answer);
    } catch (e) {
      if (mounted) {
        DetectiveService.showError(context, 'Could not get an answer');
      }
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _loadInsight() async {
    setState(() => _loading = true);

    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        setState(() {
          _error = 'No active user selected';
          _loading = false;
        });
        return;
      }

      // Get latest insight
      final insight = await _detectiveService.getLatestInsight(
        userId: userId,
        timeRange: _selectedTimeRange,
      );

      // Get history
      final history = await _detectiveService.getInsightHistory(userId: userId);

      setState(() {
        _currentInsight = insight;
        _insightHistory = history;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load insights: $e';
        _loading = false;
      });
    }
  }

  Future<void> _regenerateInsight() async {
    setState(() => _regenerating = true);

    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        setState(() => _regenerating = false);
        if (mounted) {
          DetectiveService.showError(context, 'No active user selected');
        }
        return;
      }

      final daysBack = _selectedTimeRange == 'WEEK'
          ? 7
          : _selectedTimeRange == 'MONTH'
              ? 30
              : 90;

      final insight = await _detectiveService.generateInsight(
        userId: userId,
        daysBack: daysBack,
      );

      setState(() {
        _currentInsight = insight;
        _regenerating = false;
      });

      if (mounted) {
        DetectiveService.showInsightSuccess(
          context,
          '✨ New insight generated!',
        );
      }
    } catch (e) {
      setState(() => _regenerating = false);

      if (mounted) {
        DetectiveService.showError(context, 'Failed to generate insight');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: const Text('Health Detective'),
        centerTitle: false,
      ),
      body:
          _error != null ? _buildErrorState(isDark) : _buildMainContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to Load Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInsight,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Selector
          Row(
            children: [
              _buildTimeRangeChip('WEEK', '7 Days'),
              const SizedBox(width: 8),
              _buildTimeRangeChip('MONTH', '30 Days'),
              const SizedBox(width: 8),
              _buildTimeRangeChip('ALL_TIME', 'All Time'),
            ],
          ),
          const SizedBox(height: 20),

          // Current Insight or Empty State
          if (_currentInsight != null && _currentInsight!.isValid)
            _buildInsightCard(isDark, _currentInsight!)
          else
            _buildEmptyState(isDark),

          const SizedBox(height: 24),

          // Regenerate Button
          if (_currentInsight != null && _currentInsight!.isValid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _regenerating ? null : _regenerateInsight,
                icon: _regenerating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh),
                label:
                    Text(_regenerating ? 'Analyzing...' : 'Regenerate Insight'),
              ),
            ),

          const SizedBox(height: 24),

          // Ask your health data (AI Q&A)
          _buildAskCard(isDark),

          const SizedBox(height: 24),

          // Insight History Section
          if (_insightHistory.isNotEmpty) ...[
            Text(
              'Insight History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildHistoryList(isDark),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _selectedTimeRange == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedTimeRange = value);
          _loadInsight();
        }
      },
      backgroundColor: isSelected
          ? AppColors.primaryBlue
          : Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
    );
  }

  Widget _buildInsightCard(bool isDark, DetectiveInsight insight) {
    return GestureDetector(
      onTap: () => _showInsightDetail(insight),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                insight.badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              insight.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),

            // Description (truncated)
            Text(
              insight.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),

            // Finding snippet (highlighted)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.finding,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Footer with time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  insight.generatedTimeAgo,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: AppColors.primaryBlue.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Insights Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log more health data to generate personalized AI insights about your patterns and health trends.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _regenerateInsight,
            icon: const Icon(Icons.analytics),
            label: const Text('Generate Insight'),
          ),
        ],
      ),
    );
  }

  Widget _buildAskCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Ask your health data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI answers using your recent vitals, sleep and activity.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _askQuestion(),
                  decoration: InputDecoration(
                    hintText: 'e.g. How was my sleep this week?',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _asking ? null : _askQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _asking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_answer != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _answer!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildHistoryList(bool isDark) {
    return _insightHistory.map((insight) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _showInsightDetail(insight),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${insight.timeRangeLabel} • ${insight.generatedTimeAgo}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showInsightDetail(DetectiveInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: DetectiveInsightDetail(insight: insight),
        ),
      ),
    );
  }
}
