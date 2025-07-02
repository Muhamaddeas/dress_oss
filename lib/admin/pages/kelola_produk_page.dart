import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class KelolaProdukPage extends StatefulWidget {
  const KelolaProdukPage({super.key});

  @override
  State<KelolaProdukPage> createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isUploading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _imageUrl;
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('products').select('*');
      setState(() => _products = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final file = File(picked.files.first.path!);
      final fileBytes = await file.readAsBytes();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('product-images')
          .uploadBinary(fileName, fileBytes,
              fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      setState(() {
        _imageUrl = publicUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil diunggah!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload: ${e.toString()}')),
      );
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    try {
      final productData = {
        'name': _nameController.text,
        'size': _sizeController.text,
        'description': _descController.text,
        'image_url': _imageUrl,
        'price':0.0,
        'is_available': true,
      };

      if (_editingProductId == null) {
        await _supabase.from('products').insert(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
      } else {
        await _supabase
            .from('products')
            .update(productData)
            .eq('id', _editingProductId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui')),
        );
      }

      _fetchProducts();
      _resetForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _supabase.from('products').delete().eq('id', id);
      _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    _editingProductId = product?['id'];
    _nameController.text = product?['name'] ?? '';
    _sizeController.text = product?['size'] ?? '';
    _descController.text = product?['description'] ?? '';
    _imageUrl = product?['image_url'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editingProductId == null ? 'Tambah Produk' : 'Edit Produk',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nama produk harus diisi' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Ukuran',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Ukuran harus diisi' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    if (_imageUrl != null) ...[
                      Image.network(_imageUrl!, height: 100),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadImage,
                      child: _isUploading 
                          ? const CircularProgressIndicator()
                          : const Text('Unggah Gambar'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _saveProduct,
                        child: _isProcessing
                            ? const CircularProgressIndicator()
                            : Text(_editingProductId == null ? 'Simpan' : 'Perbarui'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _nameController.clear();
    _sizeController.clear();
    _descController.clear();
    _imageUrl = null;
    _editingProductId = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Belum ada produk'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: product['image_url'] != null
                            ? Image.network(product['image_url'], width: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image),
                        title: Text(product['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ukuran: ${product['size']}'),
                            if (product['description'] != null && product['description'].isNotEmpty)
                              Text('Deskripsi: ${product['description']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _isProcessing ? null : () => _showProductForm(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _isProcessing ? null : () => _deleteProduct(product['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}