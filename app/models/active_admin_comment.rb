class ActiveAdminComment < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :author, polymorphic: true

  attr_accessible :body, :namespace, :author_id, :author_type

  def self.created_in_month(dtim=DateTime.now, namespace='superadmin')
    month_start = dtim.utc.beginning_of_month
    month_end = dtim.utc.end_of_month
    start_dtim = month_start.strftime('%Y-%m-%d %H:%M:%S')
    end_dtim   = month_end.strftime('%Y-%m-%d %H:%M:%S')
    sql = "select * from active_admin_comments where namespace='#{namespace}' and created_at between '#{start_dtim}' and '#{end_dtim}' order by created_at desc"
    ActiveAdminComment.find_by_sql(sql)
  end

end
