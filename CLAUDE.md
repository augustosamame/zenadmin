# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build, Lint, and Test Commands

### JavaScript/CSS Build Commands
```bash
# Build CSS and JavaScript assets
yarn build

# Build CSS only
yarn build:css

# Build JavaScript only
yarn build:js
```

### Ruby Commands
```bash
# Run Ruby linter
bundle exec rubocop

# Run security scanner
bundle exec brakeman

# Database operations
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails db:nukedb  # Drop, create, and migrate database

# Run Rails console
bundle exec rails console

# Start Rails server
bundle exec rails server

# Start Sidekiq for background jobs
bundle exec sidekiq
```

### Deployment
```bash
# Deploy to production using Capistrano
cap production deploy

# Deploy to specific environments
cap jardindelzen deploy
cap sercam deploy
cap constructor deploy
cap staging deploy
```

## High-Level Architecture

### System Overview
This is a Ruby on Rails ERP system for retail/wholesale operations, supporting multi-tenant architecture with separate databases per client. The system handles inventory management, sales, purchasing, accounting, and compliance with Peruvian tax regulations.

### Multi-Tenancy Architecture
- **Subdomain-based tenant identification**: Each client has their own subdomain (e.g., client1.example.com)
- **Separate databases per client**: Each tenant has its own PostgreSQL database
- **Dynamic database switching**: The system switches database connections based on subdomain detection
- **Shared codebase**: All tenants share the same Rails application code but have isolated data

### Core Business Domains

#### Sales & Orders (`app/controllers/admin/orders_controller.rb`)
- Point of sale (POS) system with order management
- Multi-seller commission tracking
- Customer loyalty programs and pricing tiers
- Payment processing with multiple methods
- Order states: draft, confirmed, shipped, delivered, cancelled

#### Inventory Management
- Multi-warehouse inventory tracking (`app/models/warehouse_inventory.rb`)
- Stock transfers between warehouses (`app/models/stock_transfer.rb`)
- Automatic requisition system (`app/lib/services/inventory/automatic_requisitions_service.rb`)
- Real-time stock movement tracking (kardex system)
- Periodic inventory counts

#### Product Catalog (`app/models/product.rb`)
- Rich product management with categories, tags, and brands
- Price list support for customer-specific pricing
- Combo products and product packs
- Tax exemption support (inafecto products)
- Media attachment capabilities

#### Financial Management
- Accounts receivable/payable tracking
- Multi-method payment processing
- Credit sales management
- Cashier shift reconciliation
- Integration with Peruvian tax system (SUNAT)

#### User & Access Management
- Role-based access control (RBAC) with CanCan
- Hierarchical roles: admin, super_admin, supervisor, warehouse_manager, store_manager, store, customer
- Employee attendance tracking
- Commission calculations for sales staff

### Key Technical Components

#### Service Layer (`app/lib/services/`)
- Business logic is organized into service classes
- Notification system with strategy pattern
- Invoice generation and SUNAT integration
- Inventory movement services
- Product import services

#### Background Jobs (`app/workers/`)
- Sidekiq for background job processing
- Invoice generation workers
- Stock transfer processing
- Media processing with Shrine

#### State Management
- AASM gem for state machines on orders and stock transfers
- Complex workflow management for business processes

#### File Handling
- Shrine gem for file uploads with AWS S3 integration
- Uppy JavaScript library for enhanced file upload UX
- Direct S3 uploads with presigned URLs

### Database & Models

#### Core Models
- `Order` - Central sales entity with complex business logic
- `Product` - Product catalog with inventory tracking
- `Customer` - Customer management with loyalty integration
- `User` - User management with RBAC
- `WarehouseInventory` - Real-time stock tracking

#### Key Relationships
- Orders have multiple OrderItems and OrderSellers
- Products belong to Categories and can have multiple Tags
- Users have multiple Roles through UserRoles
- Warehouses contain WarehouseInventory for Products

### Frontend Architecture

#### Hotwire Integration
- Turbo for SPA-like navigation
- Stimulus controllers for interactive components
- Real-time updates using Turbo Streams

#### JavaScript Build System
- esbuild for JavaScript bundling
- Tailwind CSS for styling
- jQuery DataTables for data grids
- Various specialized libraries (ApexCharts, FullCalendar, etc.)

### Notification System
The system uses a flexible notification architecture:
- `CreateNotificationService` with strategy pattern
- Multiple delivery methods: feed, email, dashboard alerts
- Configurable notification settings per trigger type
- Real-time notifications using Action Cable

### Development Patterns

#### Concerns (`app/models/concerns/`)
- `Auditable` - Audit trail functionality
- `CustomNumberable` - Automatic ID generation with prefixes
- `DefaultRegionable` - Multi-region support
- `MediaAttachable` - File attachment capabilities

#### Controller Organization
- Admin namespace contains all business logic controllers
- Location-aware operations for multi-location support
- Currency formatting helpers

### Key Configuration Files
- `config/database.yml` - Multi-tenant database configuration
- `config/routes.rb` - Extensive admin namespace routing
- `config/initializers/shrine.rb` - File upload configuration
- `config/deploy.rb` - Capistrano deployment configuration

### Security & Compliance
- SUNAT electronic invoicing integration
- Tax-compliant receipt generation
- Comprehensive audit trail system
- Role-based access control throughout

### Performance Considerations
- Connection pooling for database switching
- Background job processing for heavy operations
- Caching strategies for frequently accessed data
- Efficient database queries with proper indexing

This ERP system is designed for medium to large retail operations requiring sophisticated inventory management, multi-location support, and compliance with Peruvian tax regulations.