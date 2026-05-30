// ============================================================
//  Domain Entities
// ============================================================

class UserEntity {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String direccion;
  final String rol;

  const UserEntity({
    required this.id, required this.nombre, required this.apellido,
    required this.email, required this.telefono, required this.direccion,
    required this.rol,
  });

  String get fullName => '$nombre $apellido';
  bool get isAdmin    => rol == 'admin';
  bool get isEmpleado => rol == 'empleado';
  bool get isCliente  => rol == 'cliente';

  factory UserEntity.fromJson(Map<String, dynamic> j) => UserEntity(
    id: j['id'] ?? 0, nombre: j['nombre'] ?? '', apellido: j['apellido'] ?? '',
    email: j['email'] ?? '', telefono: j['telefono'] ?? '',
    direccion: j['direccion'] ?? '', rol: j['rol'] ?? 'cliente',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'apellido': apellido, 'email': email,
    'telefono': telefono, 'direccion': direccion, 'rol': rol,
  };
}

// ---- Category ----
class CategoryEntity {
  final int id;
  final String nombre;
  final String descripcion;
  final String icono;

  const CategoryEntity({required this.id, required this.nombre, required this.descripcion, required this.icono});

  factory CategoryEntity.fromJson(Map<String, dynamic> j) => CategoryEntity(
    id: j['id'] ?? 0, nombre: j['nombre'] ?? '',
    descripcion: j['descripcion'] ?? '', icono: j['icono'] ?? '',
  );
}

// ---- Product ----
class ProductEntity {
  final int id;
  final int categoryId;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String imagenUrl;
  final bool destacado;
  final String categoria;

  const ProductEntity({
    required this.id, required this.categoryId, required this.nombre,
    required this.descripcion, required this.precio, required this.stock,
    required this.imagenUrl, required this.destacado, required this.categoria,
  });

  factory ProductEntity.fromJson(Map<String, dynamic> j) => ProductEntity(
    id: j['id'] ?? 0, categoryId: j['category_id'] ?? 0,
    nombre: j['nombre'] ?? '', descripcion: j['descripcion'] ?? '',
    precio: (j['precio'] ?? 0).toDouble(), stock: j['stock'] ?? 0,
    imagenUrl: j['imagen_url'] ?? '', destacado: j['destacado'] == true || j['destacado'] == 1,
    categoria: j['categoria'] ?? '',
  );
}

// ---- Cart Item ----
class CartItemEntity {
  final int id;
  final int productId;
  final String nombre;
  final double precio;
  final String imagenUrl;
  final int cantidad;
  final double subtotal;
  final int stock;

  const CartItemEntity({
    required this.id, required this.productId, required this.nombre,
    required this.precio, required this.imagenUrl, required this.cantidad,
    required this.subtotal, required this.stock,
  });

  factory CartItemEntity.fromJson(Map<String, dynamic> j) => CartItemEntity(
    id: j['id'] ?? 0, productId: j['product_id'] ?? 0,
    nombre: j['nombre'] ?? '', precio: (j['precio'] ?? 0).toDouble(),
    imagenUrl: j['imagen_url'] ?? '', cantidad: j['cantidad'] ?? 1,
    subtotal: (j['subtotal'] ?? 0).toDouble(), stock: j['stock'] ?? 0,
  );
}

// ---- Order ----
class OrderEntity {
  final int id;
  final String estado;
  final double total;
  final String tipoEntrega;
  final String direccionEntrega;
  final String notas;
  final String createdAt;
  final String? cliente;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id, required this.estado, required this.total,
    required this.tipoEntrega, required this.direccionEntrega,
    required this.notas, required this.createdAt,
    this.cliente, this.items = const [],
  });

  factory OrderEntity.fromJson(Map<String, dynamic> j) => OrderEntity(
    id: j['id'] ?? 0, estado: j['estado'] ?? '',
    total: (j['total'] ?? 0).toDouble(), tipoEntrega: j['tipo_entrega'] ?? 'tienda',
    direccionEntrega: j['direccion_entrega'] ?? '', notas: j['notas'] ?? '',
    createdAt: j['created_at'] ?? '', cliente: j['cliente'],
    items: (j['items'] as List? ?? []).map((e) => OrderItemEntity.fromJson(e)).toList(),
  );
}

class OrderItemEntity {
  final int id;
  final String producto;
  final int cantidad;
  final double precioUnit;
  final double subtotal;
  final String imagenUrl;

  const OrderItemEntity({
    required this.id, required this.producto, required this.cantidad,
    required this.precioUnit, required this.subtotal, required this.imagenUrl,
  });

  factory OrderItemEntity.fromJson(Map<String, dynamic> j) => OrderItemEntity(
    id: j['id'] ?? 0, producto: j['producto'] ?? '',
    cantidad: j['cantidad'] ?? 1, precioUnit: (j['precio_unit'] ?? 0).toDouble(),
    subtotal: (j['subtotal'] ?? 0).toDouble(), imagenUrl: j['imagen_url'] ?? '',
  );
}
