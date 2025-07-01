import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ChartPage.dart';
import 'home_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(homeProvider.notifier).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(() {})
      ..dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final isSearching = _searchController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          automaticallyImplyLeading: false,
          title: const Text('Your Watchlist'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  hintText: 'Search any coin…',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: isSearching
                  ? _buildSearchResults(state)
                  : _buildFavorites(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(HomeState state) {
    return ListView.separated(
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
      itemBuilder: (ctx, i) {
        final coin = state.searchResults[i];
        final isFav = state.favoriteSet.contains(coin.symbol);

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text('${coin.symbol} (${coin.base})', style: const TextStyle(color: Colors.white)),
            subtitle: Text(coin.quote, style: const TextStyle(color: Colors.white60)),
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white54,
              ),
              onPressed: () async {
                await ref.read(homeProvider.notifier).toggleFavorite(coin.symbol);
                ref.read(homeProvider.notifier).search(_searchController.text);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavorites(HomeState state) {
    final favList = state.favoriteSet.toList();

    if (favList.isEmpty) {
      return const Center(
        child: Text('No favorites yet.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.separated(
      itemCount: favList.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
      itemBuilder: (ctx, i) {
        final sym = favList[i];
        final price = state.prices[sym] ?? '–';
        final change = state.changes[sym] ?? '–';

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text('$sym (${sym.replaceAll('USDT', '')})',
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('24h Change: $change%',
                style: TextStyle(
                  color: double.tryParse(change)?.isNegative == true
                      ? Colors.red
                      : Colors.green,
                )),
            trailing: Text('\$$price', style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartPage(symbol: sym)),
              );
            },
          ),
        );
      },
    );
  }
}
