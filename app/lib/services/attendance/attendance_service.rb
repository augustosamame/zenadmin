module Services
  module Attendance
    class AttendanceService
      def initialize(user)
        @user = user
      end

      def generate_user_attendance_report(start_date, end_date)
        {
          daily: user_daily_report(start_date, end_date),
          monthly: user_monthly_report(start_date, end_date)
        }
      end

      def generate_location_attendance_report(start_date, end_date)
        {
          daily: location_daily_report(start_date, end_date),
          monthly: location_monthly_report(start_date, end_date)
        }
      end

      private

      def user_daily_report(start_date, end_date)
        @user.user_attendance_logs
             .where(check_in: start_date.beginning_of_day..end_date.end_of_day)
             .group(:location_id)
             .group_by_day(:check_in)
             .sum(hours_worked_sql)
      end

      def user_monthly_report(start_date, end_date)
        @user.user_attendance_logs
             .where(check_in: start_date.beginning_of_month..end_date.end_of_month)
             .group(:location_id)
             .group_by_month(:check_in)
             .sum(hours_worked_sql)
      end

      def location_daily_report(start_date, end_date)
        UserAttendanceLog
          .where(check_in: start_date.beginning_of_day..end_date.end_of_day)
          .group(:location_id, :user_id)
          .group_by_day(:check_in)
          .sum(hours_worked_sql)
      end

      def location_monthly_report(start_date, end_date)
        UserAttendanceLog
          .where(check_in: start_date.beginning_of_month..end_date.end_of_month)
          .group(:location_id, :user_id)
          .group_by_month(:check_in)
          .sum(hours_worked_sql)
      end

      def hours_worked_sql
        "EXTRACT(EPOCH FROM (COALESCE(check_out, CURRENT_TIMESTAMP) - check_in)) / 3600"
      end
    end
  end
end
