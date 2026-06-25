// ============================================================
//  Domain Entities
// ============================================================
import 'dart:convert';

class UserEntity {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String direccion;
  final int? rolId;
  final String rol;
  final List<String> permisos;
  final String? imagenUrl;
  final bool isVerified;

  const UserEntity({
    required this.id, required this.nombre, required this.apellido,
    required this.email, required this.telefono, required this.direccion,
    this.rolId, required this.rol, this.permisos = const [], this.imagenUrl,
    this.isVerified = true,
  });

  String get fullName => '$nombre $apellido';
  bool get isAdmin    => rol == 'Super Admin' || rol == 'admin';
  bool get isEmpleado => rol == 'empleado';
  bool get isCliente  => rol == 'cliente';
  bool hasPermission(String p) => isAdmin || permisos.contains('manage_all') || permisos.contains(p);

  factory UserEntity.fromJson(Map<String, dynamic> j) => UserEntity(
    id: j['id'] ?? 0, nombre: j['nombre'] ?? '', apellido: j['apellido'] ?? '',
    email: j['email'] ?? '', telefono: j['telefono'] ?? '',
    direccion: j['direccion'] ?? '', rolId: j['rol_id'], rol: j['rol'] ?? 'cliente',
    permisos: List<String>.from(j['permisos'] ?? []),
    imagenUrl: j['imagen_url'],
    isVerified: j['is_verified'] == true || j['is_verified'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'apellido': apellido, 'email': email,
    'telefono': telefono, 'direccion': direccion, 'rol_id': rolId, 'rol': rol,
    'permisos': permisos, 'imagen_url': imagenUrl, 'is_verified': isVerified,
  };
}

// ---- Role ----
class RoleEntity {
  final int id;
  final String nombre;
  final String descripcion;
  final List<String> permisos;

  const RoleEntity({
    required this.id, required this.nombre, 
    required this.descripcion, required this.permisos
  });

  factory RoleEntity.fromJson(Map<String, dynamic> j) => RoleEntity(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0, 
    nombre: j['nombre'] ?? '', 
    descripcion: j['descripcion'] ?? '',
    permisos: List<String>.from(j['permisos'] ?? []),
  );
}

// ---- Category ----
class CategoryEntity {
  final int id;
  final String nombre;
  final String descripcion;
  final String icono;

  const CategoryEntity({required this.id, required this.nombre, required this.descripcion, required this.icono});

  factory CategoryEntity.fromJson(Map<String, dynamic> j) => CategoryEntity(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0,
    nombre: j['nombre'] ?? '',
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
  final bool activo;
  final List<Map<String, dynamic>> adicionales;
  final List<String> imagenesUrl;

  const ProductEntity({
    required this.id, required this.categoryId, required this.nombre,
    required this.descripcion, required this.precio, required this.stock,
    required this.imagenUrl, required this.destacado, required this.categoria,
    this.activo = true,
    this.adicionales = const [],
    this.imagenesUrl = const [],
  });

  List<String> get allImages => imagenesUrl.isNotEmpty ? imagenesUrl : [imagenUrl];

  factory ProductEntity.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> parsedAdicionales = [];
    final rawAdicionales = j['adicionales'];
    if (rawAdicionales != null) {
      if (rawAdicionales is List) {
        parsedAdicionales = rawAdicionales.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (rawAdicionales is String && rawAdicionales.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawAdicionales);
          if (decoded is List) {
            parsedAdicionales = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (_) {}
      }
    }

    List<String> parsedImagenes = [];
    final rawImagenes = j['imagenes_url'];
    if (rawImagenes != null) {
      if (rawImagenes is List) {
        parsedImagenes = List<String>.from(rawImagenes);
      } else if (rawImagenes is String && rawImagenes.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawImagenes);
          if (decoded is List) {
            parsedImagenes = List<String>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return ProductEntity(
      id: j['id'] ?? 0,
      categoryId: j['category_id'] ?? 0,
      nombre: j['nombre'] ?? '',
      descripcion: j['descripcion'] ?? '',
      precio: (j['precio'] ?? 0).toDouble(),
      stock: j['stock'] ?? 0,
      imagenUrl: j['imagen_url'] ?? '',
      destacado: j['destacado'] == true || j['destacado'] == 1,
      categoria: j['categoria'] ?? '',
      activo: j['activo'] == true || j['activo'] == 1,
      adicionales: parsedAdicionales,
      imagenesUrl: parsedImagenes,
    );
  }
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
  final Map<String, dynamic>? opcionesPersonalizadas;

  const CartItemEntity({
    required this.id, required this.productId, required this.nombre,
    required this.precio, required this.imagenUrl, required this.cantidad,
    required this.subtotal, required this.stock, this.opcionesPersonalizadas,
  });

  factory CartItemEntity.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? parsedOpciones;
    final rawOpciones = j['opciones_personalizadas'];
    if (rawOpciones != null) {
      if (rawOpciones is Map<String, dynamic>) {
        parsedOpciones = rawOpciones;
      } else if (rawOpciones is String && rawOpciones.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawOpciones);
          if (decoded is Map<String, dynamic>) {
            parsedOpciones = decoded;
          }
        } catch (_) {}
      }
    }

    return CartItemEntity(
      id: j['id'] ?? 0,
      productId: j['product_id'] ?? 0,
      nombre: j['nombre'] ?? '',
      precio: (j['precio'] ?? 0).toDouble(),
      imagenUrl: j['imagen_url'] ?? '',
      cantidad: j['cantidad'] ?? 1,
      subtotal: (j['subtotal'] ?? 0).toDouble(),
      stock: j['stock'] ?? 0,
      opcionesPersonalizadas: parsedOpciones,
    );
  }
}

// ---- Order ----
class OrderEntity {
  final int id;
  final int userId;
  final String? cliente;
  final String? email;
  final String? telefono;
  final String estado;
  final double total;
  final String tipoEntrega;
  final String direccionEntrega;
  final String notas;
  final String tipoComprobante;
  final String documentoCliente;
  final String createdAt;
  final List<OrderItemEntity> items;
  final List<OrderStatusHistoryEntity> historial;

  const OrderEntity({
    required this.id, required this.userId, this.cliente, this.email, this.telefono,
    required this.estado, required this.total, required this.tipoEntrega,
    required this.direccionEntrega, required this.notas,
    required this.tipoComprobante, required this.documentoCliente,
    required this.createdAt, this.items = const [], this.historial = const [],
  });

  factory OrderEntity.fromJson(Map<String, dynamic> j) => OrderEntity(
    id: j['id'] ?? 0, userId: j['user_id'] ?? 0, cliente: j['cliente'],
    email: j['email'], telefono: j['telefono'],
    estado: j['estado'] ?? 'pendiente', total: (j['total'] ?? 0).toDouble(),
    tipoEntrega: j['tipo_entrega'] ?? 'tienda', direccionEntrega: j['direccion_entrega'] ?? '',
    notas: j['notas'] ?? '',
    tipoComprobante: j['tipo_comprobante'] ?? 'boleta',
    documentoCliente: j['documento_cliente'] ?? '',
    createdAt: j['created_at'] ?? '',
    items: (j['items'] as List?)?.map((e) => OrderItemEntity.fromJson(e)).toList() ?? [],
    historial: (j['historial'] as List?)?.map((e) => OrderStatusHistoryEntity.fromJson(e)).toList() ?? [],
  );
}

class OrderItemEntity {
  final int id;
  final String producto;
  final int cantidad;
  final double precioUnit;
  final double subtotal;
  final String imagenUrl;
  final Map<String, dynamic>? opcionesPersonalizadas;

  const OrderItemEntity({
    required this.id, required this.producto, required this.cantidad,
    required this.precioUnit, required this.subtotal, required this.imagenUrl,
    this.opcionesPersonalizadas,
  });

  factory OrderItemEntity.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? parsedOpciones;
    final rawOpciones = j['opciones_personalizadas'];
    if (rawOpciones != null) {
      if (rawOpciones is Map<String, dynamic>) {
        parsedOpciones = rawOpciones;
      } else if (rawOpciones is String && rawOpciones.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawOpciones);
          if (decoded is Map<String, dynamic>) {
            parsedOpciones = decoded;
          }
        } catch (_) {}
      }
    }

    return OrderItemEntity(
      id: j['id'] ?? 0,
      producto: j['producto'] ?? '',
      cantidad: j['cantidad'] ?? 1,
      precioUnit: (j['precio_unit'] ?? 0).toDouble(),
      subtotal: (j['subtotal'] ?? 0).toDouble(),
      imagenUrl: j['imagen_url'] ?? '',
      opcionesPersonalizadas: parsedOpciones,
    );
  }
}

class OrderStatusHistoryEntity {
  final int id;
  final int orderId;
  final String estado;
  final int? changedBy;
  final String? cambiadoPor;
  final String notas;
  final String createdAt;

  const OrderStatusHistoryEntity({
    required this.id, required this.orderId, required this.estado,
    this.changedBy, this.cambiadoPor, required this.notas, required this.createdAt,
  });

  factory OrderStatusHistoryEntity.fromJson(Map<String, dynamic> j) => OrderStatusHistoryEntity(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0,
    orderId: j['order_id'] is int ? j['order_id'] : int.tryParse(j['order_id']?.toString() ?? '') ?? 0,
    estado: j['estado'] ?? '',
    changedBy: j['changed_by'] is int ? j['changed_by'] : int.tryParse(j['changed_by']?.toString() ?? ''),
    cambiadoPor: j['cambiado_por'],
    notas: j['notas'] ?? '',
    createdAt: j['created_at'] ?? '',
  );
}

// ---- Supplier ----
class SupplierEntity {
  final int id;
  final String nombre;
  final String empresa;
  final String telefono;
  final String email;
  final String direccion;
  final String ruc;
  final bool activo;

  const SupplierEntity({
    required this.id, required this.nombre, required this.empresa,
    required this.telefono, required this.email, required this.direccion,
    required this.ruc, required this.activo,
  });

  factory SupplierEntity.fromJson(Map<String, dynamic> j) => SupplierEntity(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0, 
    nombre: j['nombre'] ?? '', empresa: j['empresa'] ?? '',
    telefono: j['telefono'] ?? '', email: j['email'] ?? '',
    direccion: j['direccion'] ?? '', ruc: j['ruc'] ?? '',
    activo: j['activo'] == true || j['activo'] == 1,
  );
}

// ---- Employee Profile ----
class EmployeeProfileEntity {
  final int userId;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final bool activo;
  final String rol;
  final int? profileId;
  final String cargo;
  final String fechaContratacion;
  final double salario;
  final String horario;
  final String notas;

  const EmployeeProfileEntity({
    required this.userId, required this.nombre, required this.apellido,
    required this.email, required this.telefono, required this.activo, required this.rol,
    this.profileId, required this.cargo, required this.fechaContratacion,
    required this.salario, required this.horario, required this.notas,
  });

  factory EmployeeProfileEntity.fromJson(Map<String, dynamic> j) => EmployeeProfileEntity(
    userId: j['user_id'] ?? 0, nombre: j['nombre'] ?? '', apellido: j['apellido'] ?? '',
    email: j['email'] ?? '', telefono: j['telefono'] ?? '',
    activo: j['activo'] == true || j['activo'] == 1, rol: j['rol'] ?? '',
    profileId: j['profile_id'], cargo: j['cargo'] ?? '',
    fechaContratacion: j['fecha_contratacion'] ?? '',
    salario: (j['salario'] ?? 0).toDouble(), horario: j['horario'] ?? '',
    notas: j['notas'] ?? '',
  );
}

// ---- Log ----
class LogEntity {
  final int id;
  final int? userId;
  final String userNombre;
  final String userEmail;
  final String accion;
  final String modulo;
  final String descripcion;
  final String ipAddress;
  final String createdAt;

  const LogEntity({
    required this.id, this.userId, required this.userNombre, required this.userEmail,
    required this.accion, required this.modulo, required this.descripcion,
    required this.ipAddress, required this.createdAt,
  });

  factory LogEntity.fromJson(Map<String, dynamic> j) => LogEntity(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0, 
    userId: j['user_id'] is int ? j['user_id'] : int.tryParse(j['user_id']?.toString() ?? ''), 
    userNombre: j['user_nombre'] ?? 'Sistema',
    userEmail: j['user_email'] ?? '', accion: j['accion'] ?? '',
    modulo: j['modulo'] ?? '', descripcion: j['descripcion'] ?? '',
    ipAddress: j['ip_address'] ?? '', createdAt: j['created_at'] ?? '',
  );
}

// ---- Notification ----
class NotificationEntity {
  final int id;
  final int userId;
  final String titulo;
  final String mensaje;
  final bool leida;
  final String tipo;
  final String createdAt;

  const NotificationEntity({
    required this.id, required this.userId, required this.titulo,
    required this.mensaje, required this.leida, required this.tipo,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> j) => NotificationEntity(
    id: j['id'] ?? 0, userId: j['user_id'] ?? 0, titulo: j['titulo'] ?? '',
    mensaje: j['mensaje'] ?? '', leida: j['leida'] == true || j['leida'] == 1,
    tipo: j['tipo'] ?? 'info', createdAt: j['created_at'] ?? '',
  );
}

// ---- Purchase ----
class PurchaseEntity {
  final int id;
  final int supplierId;
  final String supplierNombre;
  final int userId;
  final String userNombre;
  final double total;
  final String estado;
  final String fecha;
  final String notas;
  final String createdAt;
  final List<PurchaseItemEntity> items;

  const PurchaseEntity({
    required this.id, required this.supplierId, required this.supplierNombre,
    required this.userId, required this.userNombre, required this.total,
    required this.estado, required this.fecha, required this.notas,
    required this.createdAt, this.items = const [],
  });

  factory PurchaseEntity.fromJson(Map<String, dynamic> j) => PurchaseEntity(
    id: j['id'] ?? 0, supplierId: j['supplier_id'] ?? 0, supplierNombre: j['supplier_nombre'] ?? '',
    userId: j['user_id'] ?? 0, userNombre: j['user_nombre'] ?? '',
    total: (j['total'] ?? 0).toDouble(), estado: j['estado'] ?? '',
    fecha: j['fecha'] ?? '', notas: j['notas'] ?? '', createdAt: j['created_at'] ?? '',
    items: (j['items'] as List? ?? []).map((e) => PurchaseItemEntity.fromJson(e)).toList(),
  );
}

class PurchaseItemEntity {
  final int id;
  final int productId;
  final String productNombre;
  final String descripcion;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;

  const PurchaseItemEntity({
    required this.id, required this.productId, required this.productNombre,
    required this.descripcion, required this.cantidad, required this.costoUnitario,
    required this.subtotal,
  });

  factory PurchaseItemEntity.fromJson(Map<String, dynamic> j) => PurchaseItemEntity(
    id: j['id'] ?? 0, productId: j['product_id'] ?? 0, productNombre: j['product_nombre'] ?? '',
    descripcion: j['descripcion'] ?? '', cantidad: j['cantidad'] ?? 1,
    costoUnitario: (j['costo_unitario'] ?? 0).toDouble(), subtotal: (j['subtotal'] ?? 0).toDouble(),
  );
}
