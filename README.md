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

This architecture provides a scalable and maintainable way to handle notifications across the application, with the flexibility to add new notification types and delivery methods as needed.



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





