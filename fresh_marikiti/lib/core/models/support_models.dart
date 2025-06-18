class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> tags;
  final int helpfulCount;
  final bool isHelpful;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.tags,
    required this.helpfulCount,
    this.isHelpful = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      tags: List<String>.from(json['tags'] ?? []),
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      isHelpful: json['is_helpful'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'tags': tags,
      'helpful_count': helpfulCount,
      'is_helpful': isHelpful,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String userId;
  final String subject;
  final String message;
  final String category;
  final String status;
  final String priority;
  final String? assignedTo;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final int? rating;
  final String? feedback;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.rating,
    this.feedback,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      assignedTo: json['assigned_to']?.toString(),
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      rating: (json['rating'] as num?)?.toInt(),
      feedback: json['feedback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'category': category,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'rating': rating,
      'feedback': feedback,
    };
  }

  bool get isResolved => status == 'resolved' || status == 'closed';
  bool get isPending => status == 'open' || status == 'pending';
  bool get isInProgress => status == 'in_progress';
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final List<String> attachments;
  final bool isFromSupport;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.attachments,
    required this.isFromSupport,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'user',
      message: json['message']?.toString() ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      isFromSupport: json['is_from_support'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message,
      'attachments': attachments,
      'is_from_support': isFromSupport,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SupportTicketDetails {
  final SupportTicket ticket;
  final List<SupportMessage> messages;
  final SupportAgent? assignedAgent;

  SupportTicketDetails({
    required this.ticket,
    required this.messages,
    this.assignedAgent,
  });

  factory SupportTicketDetails.fromJson(Map<String, dynamic> json) {
    return SupportTicketDetails(
      ticket: SupportTicket.fromJson(json['ticket'] ?? {}),
      messages: (json['messages'] as List? ?? [])
          .map((messageJson) => SupportMessage.fromJson(messageJson))
          .toList(),
      assignedAgent: json['assigned_agent'] != null
          ? SupportAgent.fromJson(json['assigned_agent'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket': ticket.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'assigned_agent': assignedAgent?.toJson(),
    };
  }
}

class SupportAgent {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;
  final String department;

  SupportAgent({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isOnline,
    required this.department,
  });

  factory SupportAgent.fromJson(Map<String, dynamic> json) {
    return SupportAgent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      isOnline: json['is_online'] == true,
      department: json['department']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'is_online': isOnline,
      'department': department,
    };
  }
}

class SupportCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int ticketCount;
  final bool isActive;

  SupportCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.ticketCount,
    this.isActive = true,
  });

  factory SupportCategory.fromJson(Map<String, dynamic> json) {
    return SupportCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'help',
      ticketCount: (json['ticket_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'ticket_count': ticketCount,
      'is_active': isActive,
    };
  }
}

class SupportMetrics {
  final int totalTickets;
  final int openTickets;
  final int resolvedTickets;
  final int pendingTickets;
  final double averageResolutionTime;
  final double customerSatisfaction;
  final Map<String, int> ticketsByCategory;
  final Map<String, int> ticketsByPriority;
  final Map<String, int> ticketsByStatus;
  final List<CategoryMetric> categoryMetrics;
  final List<AgentMetric> agentMetrics;

  SupportMetrics({
    required this.totalTickets,
    required this.openTickets,
    required this.resolvedTickets,
    required this.pendingTickets,
    required this.averageResolutionTime,
    required this.customerSatisfaction,
    required this.ticketsByCategory,
    required this.ticketsByPriority,
    required this.ticketsByStatus,
    required this.categoryMetrics,
    required this.agentMetrics,
  });

  factory SupportMetrics.fromJson(Map<String, dynamic> json) {
    return SupportMetrics(
      totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
      openTickets: (json['open_tickets'] as num?)?.toInt() ?? 0,
      resolvedTickets: (json['resolved_tickets'] as num?)?.toInt() ?? 0,
      pendingTickets: (json['pending_tickets'] as num?)?.toInt() ?? 0,
      averageResolutionTime: (json['average_resolution_time'] as num?)?.toDouble() ?? 0.0,
      customerSatisfaction: (json['customer_satisfaction'] as num?)?.toDouble() ?? 0.0,
      ticketsByCategory: Map<String, int>.from(json['tickets_by_category'] ?? {}),
      ticketsByPriority: Map<String, int>.from(json['tickets_by_priority'] ?? {}),
      ticketsByStatus: Map<String, int>.from(json['tickets_by_status'] ?? {}),
      categoryMetrics: (json['category_metrics'] as List? ?? [])
          .map((item) => CategoryMetric.fromJson(item))
          .toList(),
      agentMetrics: (json['agent_metrics'] as List? ?? [])
          .map((item) => AgentMetric.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tickets': totalTickets,
      'open_tickets': openTickets,
      'resolved_tickets': resolvedTickets,
      'pending_tickets': pendingTickets,
      'average_resolution_time': averageResolutionTime,
      'customer_satisfaction': customerSatisfaction,
      'tickets_by_category': ticketsByCategory,
      'tickets_by_priority': ticketsByPriority,
      'tickets_by_status': ticketsByStatus,
      'category_metrics': categoryMetrics.map((m) => m.toJson()).toList(),
      'agent_metrics': agentMetrics.map((m) => m.toJson()).toList(),
    };
  }
}

class CategoryMetric {
  final String category;
  final int totalTickets;
  final int resolvedTickets;
  final double resolutionRate;
  final double averageResolutionTime;
  final double satisfaction;

  CategoryMetric({
    required this.category,
    required this.totalTickets,
    required this.resolvedTickets,
    required this.resolutionRate,
    required this.averageResolutionTime,
    required this.satisfaction,
  });

  factory CategoryMetric.fromJson(Map<String, dynamic> json) {
    return CategoryMetric(
      category: json['category']?.toString() ?? '',
      totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
      resolvedTickets: (json['resolved_tickets'] as num?)?.toInt() ?? 0,
      resolutionRate: (json['resolution_rate'] as num?)?.toDouble() ?? 0.0,
      averageResolutionTime: (json['average_resolution_time'] as num?)?.toDouble() ?? 0.0,
      satisfaction: (json['satisfaction'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'total_tickets': totalTickets,
      'resolved_tickets': resolvedTickets,
      'resolution_rate': resolutionRate,
      'average_resolution_time': averageResolutionTime,
      'satisfaction': satisfaction,
    };
  }
}

class AgentMetric {
  final String agentId;
  final String agentName;
  final int assignedTickets;
  final int resolvedTickets;
  final double resolutionRate;
  final double averageResolutionTime;
  final double customerSatisfaction;
  final int activeTickets;

  AgentMetric({
    required this.agentId,
    required this.agentName,
    required this.assignedTickets,
    required this.resolvedTickets,
    required this.resolutionRate,
    required this.averageResolutionTime,
    required this.customerSatisfaction,
    required this.activeTickets,
  });

  factory AgentMetric.fromJson(Map<String, dynamic> json) {
    return AgentMetric(
      agentId: json['agent_id']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? '',
      assignedTickets: (json['assigned_tickets'] as num?)?.toInt() ?? 0,
      resolvedTickets: (json['resolved_tickets'] as num?)?.toInt() ?? 0,
      resolutionRate: (json['resolution_rate'] as num?)?.toDouble() ?? 0.0,
      averageResolutionTime: (json['average_resolution_time'] as num?)?.toDouble() ?? 0.0,
      customerSatisfaction: (json['customer_satisfaction'] as num?)?.toDouble() ?? 0.0,
      activeTickets: (json['active_tickets'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'agent_name': agentName,
      'assigned_tickets': assignedTickets,
      'resolved_tickets': resolvedTickets,
      'resolution_rate': resolutionRate,
      'average_resolution_time': averageResolutionTime,
      'customer_satisfaction': customerSatisfaction,
      'active_tickets': activeTickets,
    };
  }
} 