# encoding: UTF-8

require 'spec_helper'

describe IdeasController do
  include Devise::TestHelpers # remove when helpers are globally included
  include ActionView::Helpers::UrlHelper
  render_views

  describe "#show" do
    before :each do
      @idea = Factory :idea
    end

    it "should show an idea" do
      get :show, id: @idea.id
      response.body.should include(@idea.title)
      response.body.should include(@idea.author.name)
      response.body.should include("Tehdäänkö tästä laki?")
    end

    it "should show an idea with slugged url" do
      get :show, id: "#{@idea.id}-#{@idea.slug}"
      response.body.should include(@idea.title)
      response.body.should include(@idea.author.name)
      response.body.should include("Tehdäänkö tästä laki?")
    end

    describe "logged in user" do
      before :each do
        @citizen = Factory.create :citizen
        sign_in @citizen
      end

      it "should show edit link if current_citizen is the author of the idea" do
        @idea.author = @citizen
        @idea.save!
        get :show, id: @idea.id
        response.body.should include(link_to(I18n.t("idea.links.edit_idea"), edit_idea_path(@idea)))
      end

      it "should show the voting form if not already voted" do
        get :show, id: @idea.id
        response.body.should include(@idea.title)
        response.body.should include("Tehdäänkö tästä laki?")
      end

      it "should show an option to change opinion if already voted" do
        @idea.vote(@citizen, 1)
        get :show, id: @idea.id
        response.body.should include(@idea.title)
        response.body.should include("Äänestit Kyllä,\n<br>\nvoit vaihtaa:")
      end
    end
  end

  describe "#index" do
    def create_idea(opts = {})
      idea = FactoryGirl.create :idea

      # comments
      (opts[:comments] || 0).times { FactoryGirl.create(:comment, commentable: idea) }

      # votes
      (opts[:votes] || 0).times { FactoryGirl.create(:vote, idea: idea) }

      idea
    end

    before :each do
      @idea = FactoryGirl.create :idea
      @most_voted_idea = create_idea(comments: 1, votes: 2)
      @most_commented_idea = create_idea(comments: 2, votes: 1)
    end

    it "should list three ideas" do
      get :index

      assigns(:ideas).map(&:id).should == [@most_commented_idea.id, @most_voted_idea.id, @idea.id]
    end

    it "should reverse the sorting order" do
      get :index, reorder: "age"

      assigns(:ideas).map(&:id).should == [@idea.id, @most_voted_idea.id, @most_commented_idea.id]
    end

    it "should order ideas by vote count" do
      get :index, reorder: "comments"

      assigns(:ideas).map(&:id).should == [@most_commented_idea.id, @most_voted_idea.id, @idea.id]
    end

    # # I'm really not sure how/what the code is supposed to do when reversing the sorting order
    # it "should order ideas by vote count" do
    #   session[:sorting_order] = {comments: [:most, :least]}
    #
    #   get :index, reorder: "comments"
    #
    #   session[:sorting_order][:comments].should == [:least, :most]
    #   assigns(:ideas).map(&:id).should == [@idea.id, @most_voted_idea.id, @most_commented_idea.id]
    # end
  end
end
