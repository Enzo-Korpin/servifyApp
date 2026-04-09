import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../../requests/widgets/request_card_widget.dart';

enum RequestTab {
  active,
  completed,
  canceled,
}

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final RequestService _requestService = RequestService();
  final ScrollController _scrollController = ScrollController();

  RequestTab _selectedTab = RequestTab.active;

  List<RequestModel> _requests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests(refresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 120 &&
          !_isLoadingMore &&
          !_isLoading &&
          _hasMore) {
        _fetchRequests();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _backendStatusForTab(RequestTab tab) {
    switch (tab) {
      case RequestTab.active:
        return 'pending';
      case RequestTab.completed:
        return 'accepted';
      case RequestTab.canceled:
        return null;
    }
  }

  Future<void> _fetchRequests({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _requests = [];
          _nextCursor = null;
          _hasMore = true;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
          _errorMessage = null;
        });
      }

      if (_selectedTab == RequestTab.canceled) {
        final response = await _requestService.getCanceledRequests();

        setState(() {
          _requests = response.docs;
          _hasMore = false;
        });
      } else {
        final response = await _requestService.getCustomerRequests(
          status: _backendStatusForTab(_selectedTab),
          after: refresh ? null : _nextCursor,
        );

        setState(() {
          if (refresh) {
            _requests = response.docs;
          } else {
            _requests.addAll(response.docs);
          }

          _nextCursor = response.nextCursor;
          _hasMore = response.docs.isNotEmpty && response.nextCursor != null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load requests';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _changeTab(RequestTab tab) async {
    if (_selectedTab == tab) return;

    setState(() {
      _selectedTab = tab;
    });

    await _fetchRequests(refresh: true);
  }

  String _tabText(RequestTab tab) {
    switch (tab) {
      case RequestTab.active:
        return 'Active';
      case RequestTab.completed:
        return 'Completed';
      case RequestTab.canceled:
        return 'Canceled';
    }
  }

  bool _isTabSelected(RequestTab tab) => _selectedTab == tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF4F6F8),
        surfaceTintColor: const Color(0xFFF4F6F8),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildTab(RequestTab.active),
                const SizedBox(width: 10),
                _buildTab(RequestTab.completed),
                const SizedBox(width: 10),
                _buildTab(RequestTab.canceled),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchRequests(refresh: true),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(RequestTab tab) {
    final selected = _isTabSelected(tab);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _changeTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          _tabText(tab),
          style: TextStyle(
            color: selected ? Colors.black : Colors.grey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _fetchRequests(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No requests found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _requests.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return RequestCardWidget(request: _requests[index]);
      },
    );
  }
}