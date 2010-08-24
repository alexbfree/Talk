class EventsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter
  respond_to :js
  
  def report_comment
    @comment = Comment.find(params[:comment_id])
    @event = @comment.events.build( :user => current_zooniverse_user, 
                                      :title => "Comment reported by #{current_zooniverse_user.name}")
    
    @event.save
  end
  
  def report_user
    
  end
end
