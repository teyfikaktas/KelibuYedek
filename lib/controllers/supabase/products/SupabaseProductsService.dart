import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Models/product.dart';
import '../../../api.dart';

class SupabaseProductsService {
  // Supabase client'ı al
  final SupabaseClient supabase = Supabase.instance.client;

  // Cache için
  List<Product>? _cachedProducts;
  DateTime? _lastFetchTime;
  final Duration _cacheValidity = Duration(minutes: 60);

  /// Laravel'deki getActiveProducts() metodunun Supabase versiyonu
  /// Products ile Classrooms join ederek aktif ürünleri getir
  Future<List<Product>> fetchActiveProducts() async {
    // Cache kontrolü
    if (_cachedProducts != null && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference < _cacheValidity) {
        print(
            '✅ Cache\'den products döndürülüyor (${_cachedProducts!.length} adet)');
        return _cachedProducts!;
      }
    }

    try {
      // Laravel'deki sorgunun Supabase versiyonu:
      // Product::join('classrooms', 'products.classroom_id', '=', 'classrooms.id')
      //   ->orderBy('classrooms.sort')
      //   ->with('classroom')
      //   ->select('products.*')
      //   ->get();

      final response = await supabase
          .from('products')
          .select('''
            id,
            title,
            text,
            image,
            price,
            status,
            user_id,
            classroom_id,
            order,
            created_at,
            updated_at,
            classroom:classrooms(
              id,
              title,
              code,
              text,
              status,
              public,
              user_id,
              sort,
              image,
              created_at,
              updated_at
            )
          ''')
          .eq('status', 1) // Sadece aktif products
          .eq('classroom.status', 1) // Classroom da aktif
          .order('sort',
              referencedTable: 'classroom') // Classroom sort'a göre sırala
          .order('order') // Product order'a göre sırala
          .order('id'); // Son olarak id'ye göre
      // Response'u Product model'ine çevir
      List<Product> products = response.map((json) {
        // Classroom bilgisini düzenle
        Map<String, dynamic> productJson = Map<String, dynamic>.from(json);

        // Classroom bilgisini doğru formatta ayarla
        if (productJson['classroom'] != null) {
          productJson['classroom'] = productJson['classroom'];
        }

        return Product.fromJson(productJson);
      }).toList();

      // Cache'e kaydet
      _cachedProducts = products;
      _lastFetchTime = DateTime.now();

      print(
          '✅ ${products.length} aktif product başarıyla alındı ve cache\'lendi');

      // Debug: İlk birkaç ürünün bilgilerini yazdır
      if (products.isNotEmpty) {
        print(
            '📱 İlk product: ${products.first.title} (classroom: ${products.first.classroom?.title})');
      }

      return products;
    } catch (e) {
      // Cache'de veri varsa onu döndür
      if (_cachedProducts != null) {
        return _cachedProducts!;
      }

      throw Exception('Ürünler yüklenemedi: $e');
    }
  }

  /// Belirli bir classroom'daki products'ları getir
  Future<List<Product>> fetchProductsByClassroom(int classroomId) async {
    try {
      final response = await supabase
          .from('products')
          .select('''
            id,
            title,
            text,
            image,
            price,
            status,
            user_id,
            classroom_id,
            order,
            created_at,
            updated_at,
            classroom:classrooms(*)
          ''')
          .eq('classroom_id', classroomId)
          .eq('status', 1)
          .eq('deleted_at', '')
          .order('order')
          .order('id');

      List<Product> products =
          response.map((json) => Product.fromJson(json)).toList();
      return products;
    } catch (e) {
      throw Exception('Sınıf ürünleri yüklenemedi: $e');
    }
  }

  /// Tek bir product'ı detaylarıyla getir
  Future<Product?> fetchProduct(int productId) async {
    try {
      final response = await supabase.from('products').select('''
            id,
            title,
            text,
            image,
            price,
            status,
            user_id,
            classroom_id,
            order,
            created_at,
            updated_at,
            classroom:classrooms(*)
          ''').eq('id', productId).maybeSingle();

      if (response == null) {
        return null;
      }

      Product product = Product.fromJson(response);
      return product;
    } catch (e) {
      throw Exception('Ürün detayları yüklenemedi: $e');
    }
  }

  /// Tüm aktif classrooms'ları getir
  Future<List<Map<String, dynamic>>> fetchClassrooms() async {
    try {
      final response = await supabase
          .from('classrooms')
          .select('*')
          .eq('status', 1)
          .order('sort')
          .order('id');
      return response;
    } catch (e) {
      throw Exception('Sınıflar yüklenemedi: $e');
    }
  }

  /// Cache'i temizle
  void clearCache() {
    _cachedProducts = null;
    _lastFetchTime = null;
  }

  /// Cache'in geçerli olup olmadığını kontrol et
  bool isCacheValid() {
    if (_cachedProducts == null || _lastFetchTime == null) {
      return false;
    }

    final difference = DateTime.now().difference(_lastFetchTime!);
    return difference < _cacheValidity;
  }

  /// Cache bilgilerini al
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedData': _cachedProducts != null,
      'cachedProductCount': _cachedProducts?.length ?? 0,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'isCacheValid': isCacheValid(),
      'cacheValidityMinutes': _cacheValidity.inMinutes,
    };
  }
}

// ApiService'e entegre etmek için extension
extension SupabaseProductsExtension on ApiService {
  static final SupabaseProductsService _supabaseProducts =
      SupabaseProductsService();

  /// Mevcut fetchActiveProducts metodunu Supabase'i kullanacak şekilde güncelle
  Future<List<Product>> fetchActiveProductsFromSupabase() async {
    try {
      final products = await _supabaseProducts.fetchActiveProducts();
      return products;
    } catch (e) {
      // Fallback: Eski API metodunu çağır
      final oldProducts = await fetchActiveProducts();
      return oldProducts;
    }
  }

  /// Supabase products service'ine erişim
  SupabaseProductsService get supabaseProducts => _supabaseProducts;
}

// Kullanım örneği:
/*

// WordSetsPage'te kullanım:
class _WordSetsPageState extends State<WordSetsPage> {
  List<Product>? _products;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Artık Supabase'den çek
      final products = await _apiService.fetchActiveProductsFromSupabase();

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

*/
