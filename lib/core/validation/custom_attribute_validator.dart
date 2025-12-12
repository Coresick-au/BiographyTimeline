import '../../shared/models/context.dart';

/// Validation result for custom attributes
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

/// Validator for context-specific custom attributes
class CustomAttributeValidator {
  /// Validates custom attributes for a specific context type and event type
  static ValidationResult validateCustomAttributes({
    required ContextType contextType,
    required String eventType,
    required Map<String, dynamic> customAttributes,
  }) {
    final errors = <String>[];

    // Get the expected schema for this context type and event type
    final schema = _getAttributeSchema(contextType, eventType);
    
    // Validate each attribute in the schema
    for (final entry in schema.entries) {
      final attributeName = entry.key;
      final attributeSchema = entry.value;
      
      final value = customAttributes[attributeName];
      
      // Check if required attribute is missing
      if (attributeSchema.required && (value == null || value == '')) {
        errors.add('Required attribute "$attributeName" is missing');
        continue;
      }
      
      // Skip validation if attribute is not present and not required
      if (value == null) continue;
      
      // Validate type
      if (!_isValidType(value, attributeSchema.type)) {
        errors.add('Attribute "$attributeName" must be of type ${attributeSchema.type}');
      }
      
      // Validate constraints
      final constraintErrors = _validateConstraints(attributeName, value, attributeSchema.constraints);
      errors.addAll(constraintErrors);
    }
    
    // Check for unexpected attributes
    for (final attributeName in customAttributes.keys) {
      if (!schema.containsKey(attributeName)) {
        errors.add('Unexpected attribute "$attributeName" for context type $contextType and event type $eventType');
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }

  /// Gets the attribute schema for a context type and event type
  static Map<String, AttributeSchema> _getAttributeSchema(ContextType contextType, String eventType) {
    switch (contextType) {
      case ContextType.person:
        return _getPersonalAttributeSchema(eventType);
      case ContextType.pet:
        return _getPetAttributeSchema(eventType);
      case ContextType.project:
        return _getProjectAttributeSchema(eventType);
      case ContextType.business:
        return _getBusinessAttributeSchema(eventType);
    }
  }

  static Map<String, AttributeSchema> _getPersonalAttributeSchema(String eventType) {
    switch (eventType) {
      case 'milestone':
        return {
          'milestone_type': AttributeSchema(
            type: AttributeType.string,
            required: false,
            constraints: {'enum': ['birthday', 'graduation', 'wedding', 'achievement', 'other']},
          ),
          'significance': AttributeSchema(
            type: AttributeType.string,
            required: false,
            constraints: {'enum': ['low', 'medium', 'high']},
          ),
        };
      case 'photo':
      case 'text':
      case 'mixed':
      default:
        return {};
    }
  }

  static Map<String, AttributeSchema> _getPetAttributeSchema(String eventType) {
    switch (eventType) {
      case 'pet_milestone':
        return {
          'weight_kg': AttributeSchema(
            type: AttributeType.double,
            required: false,
            constraints: {'min': 0.1, 'max': 200.0},
          ),
          'vaccine_type': AttributeSchema(
            type: AttributeType.string,
            required: false,
          ),
          'vet_visit': AttributeSchema(
            type: AttributeType.boolean,
            required: false,
          ),
          'mood': AttributeSchema(
            type: AttributeType.string,
            required: false,
            constraints: {'enum': ['playful', 'calm', 'excited', 'tired', 'anxious']},
          ),
        };
      case 'photo':
      case 'text':
      case 'mixed':
      default:
        return {};
    }
  }

  static Map<String, AttributeSchema> _getProjectAttributeSchema(String eventType) {
    switch (eventType) {
      case 'renovation_progress':
        return {
          'cost': AttributeSchema(
            type: AttributeType.double,
            required: false,
            constraints: {'min': 0.0},
          ),
          'contractor': AttributeSchema(
            type: AttributeType.string,
            required: false,
          ),
          'room': AttributeSchema(
            type: AttributeType.string,
            required: false,
          ),
          'phase': AttributeSchema(
            type: AttributeType.string,
            required: false,
            constraints: {'enum': ['planning', 'demolition', 'construction', 'finishing', 'complete']},
          ),
        };
      case 'photo':
      case 'text':
      case 'mixed':
      default:
        return {};
    }
  }

  static Map<String, AttributeSchema> _getBusinessAttributeSchema(String eventType) {
    switch (eventType) {
      case 'business_milestone':
        return {
          'milestone': AttributeSchema(
            type: AttributeType.string,
            required: false,
          ),
          'budget_spent': AttributeSchema(
            type: AttributeType.double,
            required: false,
            constraints: {'min': 0.0},
          ),
          'team_size': AttributeSchema(
            type: AttributeType.integer,
            required: false,
            constraints: {'min': 1},
          ),
        };
      case 'photo':
      case 'text':
      case 'mixed':
      default:
        return {};
    }
  }

  static bool _isValidType(dynamic value, AttributeType expectedType) {
    switch (expectedType) {
      case AttributeType.string:
        return value is String;
      case AttributeType.integer:
        return value is int;
      case AttributeType.double:
        return value is double || value is int;
      case AttributeType.boolean:
        return value is bool;
      case AttributeType.list:
        return value is List;
      case AttributeType.map:
        return value is Map;
    }
  }

  static List<String> _validateConstraints(String attributeName, dynamic value, Map<String, dynamic>? constraints) {
    final errors = <String>[];
    
    if (constraints == null) return errors;

    // Validate enum constraint
    if (constraints.containsKey('enum')) {
      final allowedValues = constraints['enum'] as List;
      if (!allowedValues.contains(value)) {
        errors.add('Attribute "$attributeName" must be one of: ${allowedValues.join(', ')}');
      }
    }

    // Validate min constraint
    if (constraints.containsKey('min')) {
      final min = constraints['min'];
      if (value is num && value < min) {
        errors.add('Attribute "$attributeName" must be at least $min');
      }
    }

    // Validate max constraint
    if (constraints.containsKey('max')) {
      final max = constraints['max'];
      if (value is num && value > max) {
        errors.add('Attribute "$attributeName" must be at most $max');
      }
    }

    // Validate minLength constraint
    if (constraints.containsKey('minLength')) {
      final minLength = constraints['minLength'];
      if (value is String && value.length < minLength) {
        errors.add('Attribute "$attributeName" must be at least $minLength characters long');
      }
    }

    // Validate maxLength constraint
    if (constraints.containsKey('maxLength')) {
      final maxLength = constraints['maxLength'];
      if (value is String && value.length > maxLength) {
        errors.add('Attribute "$attributeName" must be at most $maxLength characters long');
      }
    }

    return errors;
  }

  /// Adds a new context type schema (for future extensibility)
  static void registerContextSchema(ContextType contextType, Map<String, Map<String, AttributeSchema>> eventSchemas) {
    // In a real implementation, this would store the schema in a registry
    // For now, this is a placeholder for future extensibility
    print('Registering schema for context type: $contextType');
  }

  /// Adds a new event type schema for an existing context (for future extensibility)
  static void registerEventSchema(ContextType contextType, String eventType, Map<String, AttributeSchema> attributeSchema) {
    // In a real implementation, this would store the schema in a registry
    // For now, this is a placeholder for future extensibility
    print('Registering event schema for context type: $contextType, event type: $eventType');
  }
}

/// Schema definition for a custom attribute
class AttributeSchema {
  final AttributeType type;
  final bool required;
  final Map<String, dynamic>? constraints;

  const AttributeSchema({
    required this.type,
    this.required = false,
    this.constraints,
  });
}

/// Supported attribute types
enum AttributeType {
  string,
  integer,
  double,
  boolean,
  list,
  map,
}