class AttendancesController < ApplicationController
  require "date"
  require "time"
  include AttendancesHelper
  
  # 勤怠B：勤怠編集ページ
  def attendance_edit
    @user = User.find(params[:id])
    
    # 管理者のみ全ユーザーの勤怠編集ページに遷移可能 他ユーザーは自分の編集ページのみ遷移可能
    # 以下だと本番環境でバグ発生
    #if current_user.admin? || current_user?(@user)
    if current_user.admin? || current_user.id == @user.id
      #@attendance = Attendance.find(params[:id])
      #@current_day = Date.new(Date.today.year, Date.today.month, Date.today.day)
      
      # 勤怠編集　パラメーターで先月、来月も表示可
      @current_day = Date.strptime(params[:current_day])  #勤怠B：strptimeは「文字列」を「日付」に変換
      
      @last_month = @current_day.last_month
      @next_month = @current_day.next_month
      @first_day = @current_day.beginning_of_month
      @last_day = @current_day.end_of_month
      @week = %w(日 月 火 水 木 金 土 )
      
      (@first_day..@last_day).each do |d|
        if not @user.attendances.any?{|a| a.attendance_day == d}
          #@attendance = Attendance.new(attendance_day: d, user_id: @user.id) 以下の@attendanceと同意味
          @attendance1 = @user.attendances.build(attendance_day: d)
          @attendance1.save
        end
        @date = @user.attendances.where("attendance_day >= ? and attendance_day <= ?", @first_day, @last_day).order(:attendance_day)
      end
      
      # 勤怠B：在社時間と在社時間の合計、出勤日数　在社時間@company_timeはviewでは使用しない
      #@date.each do |date|
        #if date.beginning_time != nil && date.leaving_time != nil
          #@company_time = date.leaving_time - date.beginning_time
          #@start_company_time = 0
          #@total_company_time = (@total_company_time.to_f + @company_time)
          #@attendance_count = @user.attendances.where("beginning_time != ? and leaving_time != ?", nil?, nil?).count
          #@attendance_count = @user.attendances.where.not(beginning_time: blank?).where.not(leaving_time: blank?).count
        #end
      #end
    else
      flash[:warning] = "他ユーザーの編集ページへ遷移することはできません。"
      redirect_to current_user
    end
  end
  
  #勤怠B：勤怠編集ページ更新
  # def attendance_update
  #   @user = User.find(params[:id])
  #   @attendance = @user.attendances.where(attendance_day: Time.now.beginning_of_month..Time.now.end_of_month)
  #   @attendance.each do |at|
  #     if at.update_attributes(attendance_params)
  #       flash[:success] = "勤怠編集情報を更新しました。"
  #       redirect_to @user
  #     else
  #       render 'attendance_edit'
  #     end
  #   end
  # end
  
  # 勤怠B：勤怠編集ページ更新
  def attendance_update
    @user = User.find(params[:id])
    attendance_params.each do |at, bt|
      @attendance = @user.attendances.find(at)
      # 管理者も他ユーザーも未来日を更新することはできない
      if current_user.admin? && @attendance.attendance_day.future?
      elsif current_user?(@user) && @attendance.attendance_day.future?
      
      # 出勤時間、退勤時間が空欄だと更新できない
      elsif bt["beginning_time"].blank? && bt["leaving_time"].blank?
      elsif bt["beginning_time"].blank? || bt["leaving_time"].blank?
        flash[:warning] = "無効な編集内容があります。"
        
      # 出勤時間より退勤時間の方が早い時間だと更新できない
      elsif bt["beginning_time"] > bt["leaving_time"]
        flash[:warning] = "出勤時間と退勤時間に誤りがあります。"
        
      # これら以外だと更新できる
      else @attendance.update_attributes(bt)
        flash[:success] = "勤怠編集情報を更新しました。しかし、本日以降は更新できません。"
        #redirect_to @user and return
      end
    end
    redirect_to @user
  end
  
  
  private
  
    # 勤怠B：Strong Parameters fields_forに伴い、user時のコードに工夫が必要
    def attendance_params
      params.permit(attendances: [:beginning_time, :leaving_time])[:attendances]
    end
    # def attendance_params
    #   params.require(:attendance).permit(:beginning_time, :leaving_time)
    # end
    
    # def user_params
    #   params.require(:user).permit(:name, :email, :belong, :password,
    #                               :password_confirmation, :designate_work_time, :basic_work_time,
    #                               attendances_attributes: [:beginning_time, :leaving_time])
    # end
end
