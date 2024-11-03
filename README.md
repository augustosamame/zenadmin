# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
3.3.4

* Configuration

Required Settings records

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

cap production deploy

* Design Patterns

All modules are namespaced

ex. Sales::Invoice, Inventory::Product

* Roles and Abilities

we use RBAC: https://medium.com/@solidity101/%EF%B8%8F-demystifying-role-based-access-control-rbac-pattern-a-comprehensive-guide-bd18b144fc81

users and roles have a many to many relationship
all permissions and ACLs are defined in the Ability class

* Uppy / Shrine integration

1. Setup Overview

Uppy is a web-based file uploader that enhances user experience with features like real-time file upload progress and drag-and-drop functionality. Shrine is a toolkit for handling file attachments in Ruby applications, supporting multiple storage backends like Amazon S3.

2. Integration Workflow

A. File Upload Process Using Uppy

	1.	Initialize Uppy: A Stimulus JavaScript controller initializes Uppy with necessary plugins such as AwsS3 and Dashboard.
	2.	Request Presigned URL from Backend: Uppy sends an HTTP GET request to the backend to obtain a presigned URL for direct uploads to the S3 cache bucket.
	3.	Direct Upload to S3 (Cache): Uppy uses the presigned URL to upload files directly to a temporary S3 cache bucket.
	4.	Form Submission with Cached File Data: After a successful upload, Uppy retrieves the cache location (key) from the S3 response and adds this key as a hidden input in the form submitted to the backend.

B. Backend Processing with Shrine

	1.	Receive File Data in Rails: The form submission includes the S3 cache key and metadata as part of the media_attributes for the model.
	2.	Promotion from Cache to Permanent Storage: Upon form submission, Shrine promotes the file from the temporary S3 cache bucket to permanent S3 storage. This involves copying the file to a permanent location.
	3.	Generate Derivatives: Shrine generates image derivatives (such as thumb, small, and large) using an image processing library like image_processing and vips during the promotion.
	4.	Handling Background Jobs: File promotion and derivative generation can be handled by background jobs (e.g., Sidekiq) to avoid blocking the main request thread. Shrine can enqueue promotion and deletion tasks automatically.

3. Shrine Configuration

Shrine is configured with multiple storages: a temporary cache storage, a public storage for files with public access, and a private storage for files requiring signed URLs. Shrine uses several plugins to manage file processing, caching, promotion, and backgrounding.

4. Promoting Files and Generating Derivatives

	•	Promoting from Cache to Permanent Storage: Files are initially stored in the cache storage. After form submission, the promote method in Shrine copies the file from cache to permanent storage (either public or private).
	•	Generating Derivatives: When files are promoted, Shrine generates derivatives such as thumbnails or resized images using an image processing library. These derivatives are saved in the same permanent storage as the original file.

5. Usage

	1.	Adding Media to Models: The form includes file inputs managed by Uppy. Uppy uploads files directly to S3 and updates the form with the S3 cache location.
	2.	Form Submission: On form submission, cached file data is sent to the backend. Shrine processes this data, promotes it to permanent storage, and generates derivatives.
	3.	Accessing Files and Derivatives: After processing, files are accessible via URLs, and derivatives are stored in permanent storage. For example, you can access a large derivative of an image using the file URL method.

6. Troubleshooting

	•	Invalid or Missing File Data: Ensure that Uppy successfully uploads files to S3 and that the form contains the correct cached file data.
	•	Permission Issues with S3: Check the S3 bucket policies to ensure appropriate permissions for public or private access.
	•	Background Jobs Not Running: Verify that Sidekiq or another job processor is operational to handle background tasks.

This summary provides a comprehensive overview of how Uppy and Shrine work together in this application for file uploads, processing, and storage management.

* Notifications

Our application uses a flexible and extensible notification system to keep users informed about various events. The architecture is designed to support multiple notification types and delivery methods.

1. Notification Creation:
   The `CreateNotificationService` is responsible for creating notifications. It uses a strategy pattern to determine the appropriate notification type and content based on the notifiable object. Custom strategies can be defined for different notifiable types (e.g., `PartialStockTransferStrategy`, `StockTransferStrategy`).

2. Notification Settings:
   The `NotificationSetting` model allows configuration of which notification types should be sent through various media (e.g., notification feed, dashboard alert, email). This provides flexibility in how notifications are delivered for different trigger types. A NotificationSetting record mush be created for each notification type so that we can use it to send notifications to users.

3. Notification Delivery:
   The `Notification` model handles the delivery of notifications after creation. It supports multiple delivery methods:
   - Notification Feed: Real-time updates using Action Cable
   - Alert Header Icon: For displaying alerts in the application header
   - Dashboard Alert: For showing notifications on a dashboard
   - Email: For sending email notifications
   - SMS and WhatsApp: For mobile notifications (if implemented)

4. Customization:
   The system allows easy addition of new notification types and delivery methods. Custom strategies can be created by extending the `BaseStrategy` class and implementing the required methods (`title`, `body`, `image_url`).

5. User Interaction:
   Notifications can be marked as read, clicked, or opened, allowing for tracking of user engagement with notifications.

6. How to create a new notification object?

  create the strategy model
  add the trigger type to the NotificationSetting model
  add the notification setting record for the new trigger type
  add the notifiable relationship to the model that will trigger the notification
  go into each delivery method service (ex. EmailService) and add the logic to send the notification to the frontend

7. How to send notifications?
   Notifications are sent by the `CreateNotificationService` service. Example code:

   Services::Notifications::CreateNotificationService.new(stock_transfer, custom_strategy: "PartialStockTransfer").create

   if no custom_strategy is needed:

   Services::Notifications::CreateNotificationService.new(self).create (where self is an Order instance for example)

This architecture provides a scalable and maintainable way to handle notifications across the application, with the flexibility to add new notification types and delivery methods as needed.

* MultiTenancy

To handle a Rails project where each client has their own database and subdomain, you can implement multi-tenancy using a few key approaches. Here’s an outline of how you can achieve that:

1. Subdomain-based Tenant Identification

Each client has their own subdomain (e.g., client1.example.com, client2.example.com). You can use the subdomain to identify the tenant (client) and dynamically switch databases.

2. Database Configuration

For each client, create a separate database with the same schema. You will configure Rails to switch the database connection dynamically based on the tenant (client) subdomain.

3. Controller Filter for Tenant Detection

Use a before_action in your application controller to detect the subdomain and switch to the appropriate database.

Steps to Implement:

Step 1: Modify Database Configuration

Define separate databases for each client in your config/database.yml. For example:

default: &default
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  client1:
    <<: *default
    database: client1_db

  client2:
    <<: *default
    database: client2_db

  # Define other client databases similarly

You can repeat this for each environment (production, test, etc.).

Step 2: Create Controller Filter for Subdomain Detection

You need a way to detect the subdomain and connect to the correct database. You can use  a before_action filter in the ApplicationController:

class ApplicationController < ActionController::Base
  before_action :set_tenant

  private

  def set_tenant
    subdomain = request.subdomain

    case subdomain
    when 'client1'
      switch_to_database(:client1)
    when 'client2'
      switch_to_database(:client2)
    # Add other clients here
    else
      raise ActiveRecord::RecordNotFound, "Client not found"
    end
  end

  def switch_to_database(client)
    db_config = Rails.configuration.database_configuration[Rails.env][client.to_s]
    ActiveRecord::Base.establish_connection(db_config)
  end
end

This method detects the subdomain from the request, then switches to the correct database configuration based on the subdomain.

Step 3: Customize the View Based on Subdomain

To show a custom logo or any tenant-specific information, you can use the same subdomain detection logic in your views or controllers.

In your views, for example:

<% if request.subdomain == 'client1' %>
  <%= image_tag "client1_logo.png" %>
<% elsif request.subdomain == 'client2' %>
  <%= image_tag "client2_logo.png" %>
<% end %>

You can store these assets separately for each client and load them dynamically based on the subdomain.

Step 4: Maintain Separate Tenant Databases

Ensure that you keep the database schemas synchronized across all tenant databases, as they will share the same structure but contain different data for each client.

You can use migrations to update all client databases simultaneously. A good way to handle this is by looping through each database configuration and running migrations:

rake db:migrate:tenant

In your custom rake task:

namespace :db do
  desc "Run migrations for all tenants"
  task migrate: :environment do
    %w[client1 client2].each do |tenant|
      ActiveRecord::Base.establish_connection(tenant.to_sym)
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:migrate'].reenable # Re-enable for next iteration
    end
  end
end

Key Considerations:

	•	Connection Pooling: Ensure you adjust connection pooling settings properly, especially when dealing with multiple databases.
	•	Security: Each tenant should only have access to their own database to prevent data leaks.
	•	Scaling: Make sure your infrastructure can scale properly when you add more tenants.

This setup should allow you to manage different databases per client while sharing the same codebase and customizing their experience via subdomains.

Great questions! Let’s go through them one by one.

1. Performance Hit with Dynamic Database Switching

Yes, switching database connections on each request via ActiveRecord::Base.establish_connection can introduce some overhead. However, this overhead is typically minimal, especially for apps with relatively low traffic. Here are a few considerations regarding performance:

	•	Connection Pooling: Rails uses connection pooling to manage database connections efficiently. So, even though the connection is being switched on each request, once a connection is established, it remains available in the pool for subsequent requests.
	•	Optimization: If performance becomes an issue, you can optimize by using middleware or caching techniques to reuse database connections whenever possible. Middleware is generally more efficient because it’s processed before the request hits the controller.

For example, if your users make several requests during the same session (e.g., during an active login), Rails can keep the connection to the client’s database alive for the entire session, avoiding repeated connection switches.

2. Why the Custom Rake Task for Migrations?

By default, Rails migrations are only applied to the primary database in the database.yml. Rails doesn’t natively handle multi-database migrations for tenant-specific databases out of the box.

If you have multiple databases defined (like client1, client2, etc.), Rails will only migrate the default database. The migrations need to be explicitly run for each tenant database, hence the need for a custom rake task that loops through each database in your configuration.

Without this task, only one of the databases (whichever is the default or explicitly selected) will have the migrations applied. In the context of multi-tenancy, this won’t work because all databases (tenants) need to have the same schema.

The custom rake task ensures that migrations are applied to all tenant databases by switching the connection to each tenant’s database, running the migration, and then moving to the next.

3. Which Database Will Rails Apply Migrations to by Default?

Rails applies migrations to the primary database specified in the development, test, or production section of config/database.yml. In a standard setup, this is usually the first or only database mentioned under that environment.

For example, if you have this in your database.yml:

development:
  primary:
    adapter: postgresql
    database: primary_db
  client1:
    adapter: postgresql
    database: client1_db
  client2:
    adapter: postgresql
    database: client2_db

Rails will apply migrations to primary_db by default, not client1_db or client2_db, unless you specify otherwise using something like ActiveRecord::Base.establish_connection.

4. Capistrano for Deployment

Capistrano doesn’t natively support multi-database migrations either. You’ll need to modify your Capistrano tasks to handle migrations for all tenant databases.

Here’s how you can do it with Capistrano:

	1.	Create a Capistrano task for running tenant migrations:

namespace :deploy do
  desc 'Run database migrations for tenants'
  task :migrate_tenants do
    on roles(:db) do
      %w[client1 client2].each do |tenant|
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:migrate RAILS_ENV=#{fetch(:rails_env)} DATABASE=#{tenant}"
          end
        end
      end
    end
  end

  after 'deploy:migrate', 'deploy:migrate_tenants'
end

This ensures that after the primary database migrations are run, the task will also migrate the databases for each tenant.

	2.	Customize the Capistrano deploy flow:
Add the tenant migration task (migrate_tenants) as part of the deploy process by appending it to the standard deploy:migrate task.

This way, when you deploy with Capistrano, it will automatically migrate all client databases.

Conclusion

	•	Performance: Switching database connections dynamically for each request has a small performance overhead, but connection pooling helps mitigate this. If needed, you can explore optimizations like reusing connections per session.
	•	Custom Rake Task: Necessary because Rails will only apply migrations to the default database. The custom rake task ensures all tenant databases are migrated.
	•	Migrations: By default, Rails will apply migrations to the first (primary) database in database.yml.
	•	Capistrano: You’ll need to modify Capistrano to handle tenant migrations, as it doesn’t natively support multi-database setups.

Let me know if you need help fine-tuning these tasks!

Yes, you can cache the database connection for the duration of a user’s session to avoid repeatedly switching databases for each request. This approach can improve performance by ensuring that all requests from a logged-in user hit the same database without needing to re-establish the connection every time.

Here’s how you can implement this:

Steps to Cache the Database Connection for the Session

	1.	Use Rails Session or Devise’s current_user:
Once a user logs in via Devise, you can store the relevant client’s database connection details in the session or associate it with current_user. This way, you don’t need to determine the client on every request.
	2.	Establish the Connection Once:
You can establish the database connection when the user logs in, store the client information in the session, and reuse that connection across subsequent requests during the session.
	3.	Modify the ApplicationController:
You can cache the database connection by checking whether the database connection has already been set for the current session.

Here’s an example implementation:

Example Implementation:

1. Add Logic in ApplicationController

class ApplicationController < ActionController::Base
  before_action :set_client_database

  private

  def set_client_database
    if user_signed_in? && session[:client_db].present?
      # If the user is logged in and the session contains a cached database connection, use it.
      ActiveRecord::Base.establish_connection(session[:client_db])
    elsif user_signed_in?
      # Determine the client based on current_user or subdomain and cache the connection.
      client_db_config = determine_client_db(current_user) # Implement this method to get the right DB config
      ActiveRecord::Base.establish_connection(client_db_config)
      session[:client_db] = client_db_config
    else
      # Use the default database connection if no user is signed in
      ActiveRecord::Base.establish_connection(:primary)
    end
  end

  # Example method to determine the correct client database based on the user
  def determine_client_db(user)
    # You can base this on a field in the user model, the subdomain, etc.
    case user.client_id
    when 1
      :client1_db # this symbol should map to a database config in database.yml
    when 2
      :client2_db
    # Add more cases as needed
    else
      :primary # default database if not mapped
    end
  end
end

2. In Devise’s SessionsController (Optional)

You can customize Devise’s SessionsController to set the database connection right when the user logs in:

class Users::SessionsController < Devise::SessionsController
  after_action :set_client_database, only: [:create]

  private

  def set_client_database
    # Same logic as in ApplicationController, or move to a helper method.
    client_db_config = determine_client_db(current_user)
    ActiveRecord::Base.establish_connection(client_db_config)
    session[:client_db] = client_db_config
  end
end

This ensures the database connection is cached right after the user logs in.

3. Clear the Cached Connection on Logout

Don’t forget to clear the session when the user logs out to avoid maintaining stale database connections:

class Users::SessionsController < Devise::SessionsController
  after_action :clear_client_database, only: [:destroy]

  private

  def clear_client_database
    session.delete(:client_db)
    ActiveRecord::Base.establish_connection(:primary) # Restore default connection
  end
end

Why This Works:

	•	First Request: When the user logs in, you determine their client database, switch to that database, and cache the connection in the session (session[:client_db]).
	•	Subsequent Requests: On subsequent requests, instead of determining the database again, you simply check the cached connection in the session and reuse it.
	•	Performance Improvement: Since the database connection isn’t being switched on every request but rather established once and cached, the overhead is reduced.

When to Reconsider:

	•	High Traffic Applications: If you have very high traffic, you might need to fine-tune your connection pool settings or consider more advanced caching strategies.
	•	Connection Pool Size: You should ensure that your connection pool (config/database.yml settings) is large enough to handle multiple connections if many users from different tenants are logged in simultaneously.

This approach works well for your use case since all requests for a logged-in user will hit the same client database, reducing unnecessary database connection switching.

Let me know if you need more information or further clarification!

* Deployment

First you should prepare an EC2 server to be able to receive / run the project
Requirements:

Ruby 3.3.4 systemwide with jemalloc and YJIT turned on: --with-jemalloc --enable-yjit

https://github.com/ruby/ruby/blob/master/doc/yjit/yjit.md#installation

apt-get install --no-install-recommends -y libjemalloc2
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true,stats_print:true" \
    RUBY_YJIT_ENABLE="1"

bundle / bundler should be installed systemwide
run bundle





