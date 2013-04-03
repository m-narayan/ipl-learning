class UsersController < ApplicationController


  before_filter :authenticate_user!
  
  
  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end
  
  def update
    authorize! :update, @user, :message => 'Not authorized as an administrator.'
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user], :as => :admin)
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end
  
  def destroy
    authorize! :destroy, @user, :message => 'Not authorized as an administrator.'
    user = User.find(params[:id])
    unless user == current_user
      user.destroy
      redirect_to users_path, :notice => "User deleted."
    else
      redirect_to users_path, :notice => "Can't delete yourself."
    end
  end

  def add_users
    if (params[:file] == nil)
      params[:user_emails].split(",").each do |email|
        @post = User.new(:email => email ,:password => "123456789" , :ac_id => params[:ac_id])

      end
    else
      require 'spreadsheet'
      file = params[:file]
      acid =params[:ac_id]
    case File.extname(file.original_filename)
    when ".csv" then
      CSV.foreach(file.path) do |row|
        email =row[0]
        @post =User.new(:email => email ,:password => "123456789" , :ac_id => acid)
      end
    when ".xls" || "xlsx" then
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet.open(file.path, :col_sep => ',', :headers => true )
      sheet1 = book.worksheet 0
      sheet1.each do |row|
      email =row[0]
      @post =User.new(:email => email ,:password => "123456789" , :ac_id => acid)
      end
    else raise "Unknown file type: #{file.original_filename}"
    end
     
    end

    respond_to do |format|
      if @post.save
        $error =nil
        format.js
        format.html { redirect_to (account_path(params[:ac_id])) }
        flash[:success] = "user added to account successfully!!!!"
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        $error =nil
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.html { redirect_to (account_path(params[:ac_id])) }
        $error = @post

      end
    end
  end
end