require 'test_helper'

class AssetsControllerTest < ActionController::TestCase
  context "An Asset" do
    setup do
      @controller = AssetsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    context "When requesting an Asset" do
      setup do
        @asset = Factory :asset
        get :show, { :id => @asset.zooniverse_id }
      end

      should_respond_with :success
      should_render_template :show
      
      should "Display the asset zooniverse_id" do
        assert_select 'h2.asset-name', :text => @asset.zooniverse_id
      end
    end
  end
end
