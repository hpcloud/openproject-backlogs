#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Sprint, :type => :model do
  let(:sprint) { FactoryGirl.build(:sprint) }
  let(:project) { FactoryGirl.build(:project) }

  describe "Class Methods" do
    describe '#displayed_left' do
      describe "WITH display set to left" do
        before(:each) do
          sprint.version_settings = [FactoryGirl.build(:version_setting, :project => project,
                                                                     :display => VersionSetting::DISPLAY_LEFT)]
          sprint.project = project
          sprint.save!
        end

        it {
          expect(Sprint.displayed_left(project)).to match_array [sprint] }
      end

      describe "WITH a version setting defined for another project" do
        before(:each) do
          another_project = FactoryGirl.build(:project, :name => 'another project',
                                                   :identifier => 'another project')

          sprint.version_settings = [FactoryGirl.build(:version_setting, :project => another_project,
                                                                     :display => VersionSetting::DISPLAY_RIGHT)]
          sprint.project = project
          sprint.save
        end

        it { expect(Sprint.displayed_left(project)).to match_array [sprint] }
      end

      describe "WITH no version setting defined" do
        before(:each) do
          sprint.project = project
          sprint.save!
        end

        it { expect(Sprint.displayed_left(project)).to match_array [sprint] }
      end
    end

    describe '#displayed_right' do
      before(:each) do
        sprint.version_settings = [FactoryGirl.build(:version_setting, :project => project, :display => VersionSetting::DISPLAY_RIGHT)]
        sprint.project = project
        sprint.save!
      end

      it { expect(Sprint.displayed_right(project)).to match_array [sprint] }
    end

    describe '#order_by_date' do
      before(:each) do
        @sprint1 = FactoryGirl.create(:sprint, :name => "sprint1", :project => project, :start_date => Date.today + 2.days)
        @sprint2 = FactoryGirl.create(:sprint, :name => "sprint2", :project => project, :start_date => Date.today + 1.day, :effective_date => Date.today + 3.days)
        @sprint3 = FactoryGirl.create(:sprint, :name => "sprint3", :project => project, :start_date => Date.today + 1.day, :effective_date => Date.today + 2.days)
      end

      it { expect(Sprint.order_by_date[0]).to eql @sprint3 }
      it { expect(Sprint.order_by_date[1]).to eql @sprint2 }
      it { expect(Sprint.order_by_date[2]).to eql @sprint1 }
    end

    describe '#apply_to' do
      before(:each) do
        project.save
        @other_project = FactoryGirl.create(:project)
      end

      describe "WITH the version beeing shared system wide" do
        before(:each) do
          @version = FactoryGirl.create(:sprint, :name => "systemwide", :project => @other_project, :sharing => 'system')
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version beeing shared from a parent project" do
        before(:each) do
          project.set_parent!(@other_project)
          @version = FactoryGirl.create(:sprint, :name => "descended", :project => @other_project, :sharing => 'descendants')
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version beeing shared within the tree" do
        before(:each) do
          @parent_project = FactoryGirl.create(:project)
          # Setting the parent has to be in this order, don't know why yet
          @other_project.set_parent!(@parent_project)
          project.set_parent!(@parent_project)
          @version = FactoryGirl.create(:sprint, :name => "treed", :project => @other_project, :sharing => 'tree')
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version beeing shared within the tree" do
        before(:each) do
          @descendant_project = FactoryGirl.create(:project)
          @descendant_project.set_parent!(project)
          @version = FactoryGirl.create(:sprint, :name => "hierar", :project => @descendant_project, :sharing => 'hierarchy')
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end
    end
  end
end
