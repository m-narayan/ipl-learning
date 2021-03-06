class UsersController < ApplicationController

  before_filter :authenticate_user!
  
  
  def index
    authorize! :index, @user, :message => 'Not authorized as an administrator.'
    if(params[:search] != nil && params[:search] != "")
      @users = User.where("ac_id=#{params[:search]}").paginate(page: params[:page], :per_page => 15)
    else
     @users = User.paginate(page: params[:page], :per_page => 15)
   end
   

 end

 def show
  @user = User.find(params[:id])
end

def update
  authorize! :update, @user, :message => 'Not authorized as an administrator.'
  @user = User.find(params[:id])


  if @user.update_attributes(params[:user], :as => :admin)
    if params[:user][:is_active] == "0"
      redirect_to users_path, :notice => "User updated."
    else
       # Tell the UserMailer to send a welcome Email after save
       begin
        UserEnableMailer.welcome_email(@user,"").deliver
        flash[:info]= "User updated and activation mail sent !"

      rescue => e
        flash[:info] = "There is some error while sending the email .[ #{e.message}]"

      end
      redirect_to users_path
    end
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

  if(params[:file] != nil && params[:user_emails]!= "")
    flash[:error] = "Please give any one input"
    redirect_to (account_path(params[:ac_id]))
  elsif (params[:file] == nil && params[:user_emails]== "")
    flash[:error] = "Please give any one input"
    redirect_to (account_path(params[:ac_id]))
  else

    if (params[:file] == nil)
      params[:user_emails].split(",").each do |email|
        random_string = ('0'..'z').to_a.shuffle.first(8).join
        @post = User.new(:email => email ,:password => random_string , :ac_id => params[:ac_id] , :is_active => 1 )
        if Rails.env.production?
          @post.skip_confirmation!
        end
        if @post.save

          $error =nil
        end
        begin
         UserEnableMailer.welcome_email(@post,random_string).deliver
         flash[:info]= "User updated and activation mail sent !"

       rescue => e
        flash[:info] = "There is some error while sending the email .[ #{e.message}]"

      end
      

    end        

  else
    require 'spreadsheet'
    file = params[:file]
    acid =params[:ac_id]
    case File.extname(file.original_filename)
    when ".csv" then
      CSV.foreach(file.path) do |row|
        email =row[0]
        random_string = ('0'..'z').to_a.shuffle.first(8).join
        @post =User.new(:email => email ,:password => random_string , :ac_id => acid , :is_active => 1)
        
        @post.skip_confirmation!

        if @post.save

          $error =nil
        end
        begin
         UserEnableMailer.welcome_email(@post,random_string).deliver
         flash[:info]= "User updated and activation mail sent !"

       rescue => e
        flash[:info] = "There is some error while sending the email .[ #{e.message}]"

      end
      
    end
  when ".txt" then
   data=""
   File.open(file.path).each_line do |line|
    data += line
  end
  data.split(",").each do |email|
    random_string = ('0'..'z').to_a.shuffle.first(8).join
    @post =User.new(:email => email ,:password => random_string, :ac_id => acid , :is_active => 1)
    
    @post.skip_confirmation!

    if @post.save

      $error =nil
    end
    begin
     UserEnableMailer.welcome_email(@post,random_string).deliver
     flash[:info]= "User updated and activation mail sent !"

   rescue => e
    flash[:info] = "There is some error while sending the email .[ #{e.message}]"

  end
  
end
when ".xls" || "xlsx" then
  Spreadsheet.client_encoding = 'UTF-8'
  book = Spreadsheet.open(file.path, :col_sep => ',', :headers => true )
  sheet1 = book.worksheet 0
  sheet1.each do |row|
    email =row[0]
    random_string = ('0'..'z').to_a.shuffle.first(8).join
    @post =User.new(:email => email ,:password => random_string , :ac_id => acid , :is_active => 1)
    
    @post.skip_confirmation!

    if @post.save

      $error =nil
    end
    begin
     UserEnableMailer.welcome_email(@post,random_string).deliver
     flash[:info]= "User updated and activation mail sent !"

   rescue => e
    flash[:info] = "There is some error while sending the email .[ #{e.message}]"

  end
  
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

end