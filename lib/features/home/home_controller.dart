import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SymbolInfo {
  final String symbol;
  final String base;
  final String quote;

  SymbolInfo({required this.symbol, required this.base, required this.quote});

  factory SymbolInfo.fromJson(Map<String, dynamic> json) {
    return SymbolInfo(
      symbol: json['symbol'],
      base: json['base'],
      quote: json['quote'],
    );
  }
}

class PriceData {
  final Map<String, String> prices;
  final Map<String, String> changes;

  PriceData(this.prices, this.changes);
}

class HomeState {
  final List<SymbolInfo> allSymbols;
  final List<SymbolInfo> searchResults;
  final Set<String> favoriteSet;
  final Map<String, String> prices;
  final Map<String, String> changes;

  HomeState({
    this.allSymbols = const [],
    this.searchResults = const [],
    this.favoriteSet = const {},
    this.prices = const {},
    this.changes = const {},
  });

  HomeState copyWith({
    List<SymbolInfo>? allSymbols,
    List<SymbolInfo>? searchResults,
    Set<String>? favoriteSet,
    Map<String, String>? prices,
    Map<String, String>? changes,
  }) {
    return HomeState(
      allSymbols: allSymbols ?? this.allSymbols,
      searchResults: searchResults ?? this.searchResults,
      favoriteSet: favoriteSet ?? this.favoriteSet,
      prices: prices ?? this.prices,
      changes: changes ?? this.changes,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  StreamSubscription<QuerySnapshot>? _favSub;
  Timer? _debounce;

  final _priceStreamCtrl = StreamController<PriceData>.broadcast();

  HomeController() : super(HomeState()) {
    _init();
  }

  void _init() {
    _loadSymbolsFromAssets();
    _listenToFavorites();
  }

  Future<void> _loadSymbolsFromAssets() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/coin_info.json');
      final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
      final symbols = list.map(SymbolInfo.fromJson).toList();
      state = state.copyWith(allSymbols: symbols);
    } catch (e) {
      debugPrint('Error loading symbols: $e');
    }
  }

  void _listenToFavorites() {
    final uid = _auth.currentUser!.uid;
    _favSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      final favs = snap.docs.map((d) => d.id).toSet();
      state = state.copyWith(favoriteSet: favs);
      _connectWebSocket();
    });
  }

  void _connectWebSocket() {
    _wsSub?.cancel();
    _ws?.sink.close();

    final latestPrices = <String, String>{};
    final latestChanges = <String, String>{};

    if (state.favoriteSet.isEmpty) {
      state = state.copyWith(prices: {}, changes: {});
      return;
    }

    final streams = state.favoriteSet.map((s) => '${s.toLowerCase()}@ticker').join('/');
    final uri = Uri.parse('wss://stream.binance.com:9443/stream?streams=$streams');
    _ws = WebSocketChannel.connect(uri);

    _wsSub = _ws!.stream.listen((message) {
      final parsed = jsonDecode(message) as Map<String, dynamic>;
      final stream = (parsed['stream'] as String).split('@').first.toUpperCase();
      final data = parsed['data'] as Map<String, dynamic>;

      latestPrices[stream] = data['c'];
      latestChanges[stream] = data['P'];

      state = state.copyWith(prices: Map.from(latestPrices), changes: Map.from(latestChanges));
    });
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toUpperCase();
      if (q.isEmpty) {
        state = state.copyWith(searchResults: []);
      } else {
        final results = state.allSymbols.where((s) {
          return s.symbol.contains(q) ||
              s.base.contains(q) ||
              s.quote.contains(q);
        }).take(50).toList();

        state = state.copyWith(searchResults: results);
      }
    });
  }

  Future<void> toggleFavorite(String symbol) async {
    final uid = _auth.currentUser!.uid;
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(symbol);

    if (state.favoriteSet.contains(symbol)) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  void disposeAll() {
    _favSub?.cancel();
    _wsSub?.cancel();
    _ws?.sink.close();
    _priceStreamCtrl.close();
  }
}

final homeProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  final controller = HomeController();
  ref.onDispose(() => controller.disposeAll());
  return controller;
});
