import 'dart:collection';

class LruCache<K, V> {
  final int maxSize; // The maximum number of entries the cache can hold
  final LinkedHashMap<K, V> _cache = LinkedHashMap(); // Internal LinkedHashMap for caching

  LruCache({required this.maxSize}); // Constructor requiring a maximum size

  /// Retrieves the value associated with the given [key] from the cache.
  /// If the key is found, it's marked as most recently used (moved to the end).
  /// Returns the value if found, otherwise returns null.
  V? get(K key) {
    final value = _cache[key]; // Try to retrieve the value
    if (value != null) {
      _cache.remove(key); // Remove it from its current position
      _cache[key] = value; // Add it back, making it the most recently used
    }
    return value;
  }

  /// Puts a [key]-[value] pair into the cache.
  /// If the key already exists, its value is updated and it becomes the most recently used.
  /// If the cache reaches its [maxSize], the least recently used item (the first one) is removed.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key); // Remove if already present to update its position
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // Remove the least recently used (first) item
    }
    _cache[key] = value; // Add the new (or updated) item, marking it most recently used
  }

  /// Checks if the cache contains the given [key].
  bool containsKey(K key) {
    return _cache.containsKey(key);
  }

  /// Returns the current number of items in the cache.
  int get length => _cache.length;

  /// Clears all entries from the cache.
  void clear() {
    _cache.clear();
  }

  @override
  String toString() => _cache.toString();
}