require 'spec_helper'

class Location < ActiveRecord::Base
  acts_as_forest :order => "name"
end

describe "Edge::Forest" do
  let!(:usa) { Location.create! :name => "USA" }
  let!(:illinois) { Location.create! :parent => usa, :name => "Illinois" }
  let!(:chicago) { Location.create! :parent => illinois, :name => "Chicago" }
  let!(:indiana) { Location.create! :parent => usa, :name => "Indiana" }  
  let!(:canada) { Location.create! :name => "Canada" }
  let!(:british_columbia) { Location.create! :parent => canada, :name => "British Columbia" }
  
  describe "root?" do
    context "of root node" do
      it "should be true" do
        usa.root?.should == true
      end
    end
    
    context "of child node" do
      it "should be false" do
        illinois.root?.should == false
      end
    end
    
    context "of leaf node" do
      it "should be root node" do
        chicago.root?.should == false
      end
    end    
  end

  describe "root" do
    context "of root node" do
      it "should be self" do
        usa.root.should == usa
      end
    end
    
    context "of child node" do
      it "should be root node" do
        illinois.root.should == usa
      end
    end
    
    context "of leaf node" do
      it "should be root node" do
        chicago.root.should == usa
      end
    end
  end
  
  describe "parent" do
    context "of root node" do
      it "should be nil" do
        usa.parent.should == nil
      end
    end
    
    context "of child node" do
      it "should be parent" do
        illinois.parent.should == usa
      end
    end
    
    context "of leaf node" do
      it "should be parent" do
        chicago.parent.should == illinois
      end
    end
  end
  
  describe "ancestors" do
    context "of root node" do
      it "should be empty" do
        usa.ancestors.should be_empty
      end
    end
    
    context "of leaf node" do
      it "should be ancestors ordered by ascending distance" do
        chicago.ancestors.should == [illinois, usa]
      end
    end
  end
  
  describe "siblings" do
    context "of root node" do
      it "should be empty" do
        usa.siblings.should be_empty
      end
    end
    
    context "of child node" do
      it "should be other children of parent" do
        illinois.siblings.should include(indiana)
      end
    end
  end
  
  describe "children" do
    it "should be children" do
      usa.children.should include(illinois, indiana)
    end
    
    it "should be ordered" do
      alabama = Location.create! :parent => usa, :name => "Alabama"
      usa.children.should == [alabama, illinois, indiana]
    end
    
    context "of leaf" do
      it "should be empty" do
        chicago.children.should be_empty
      end
    end
  end
  
  describe "descendants" do
    it "should be all descendants" do
      usa.descendants.should include(illinois, indiana, chicago)
    end
    
    context "of leaf" do
      it "should be empty" do
        chicago.descendants.should be_empty
      end
    end
  end
  
  describe "root scope" do
    it "returns only root nodes" do
      Location.root.all.should include(usa, canada)
    end
  end
  
  describe "find_forest" do
    it "preloads all parents and children" do
      forest = Location.find_forest

      Location.with_scope(
        :find => Location.where("purposely fail if any Location find happens here")
      ) do
        forest.each do |tree|
          tree.descendants.each do |node|
            node.parent.should be
            node.children.should be_kind_of(Array)
          end
        end
      end
    end
    
    it "works when scoped" do
      forest = Location.where(:name => "USA").find_forest
      forest.should include(usa)
    end
    
    it "preloads children in proper order" do
      alabama = Location.create! :parent => usa, :name => "Alabama"
      forest = Location.find_forest
      tree = forest.find { |l| l.id == usa.id }
      tree.children.should == [alabama, illinois, indiana]
    end
  end
end
